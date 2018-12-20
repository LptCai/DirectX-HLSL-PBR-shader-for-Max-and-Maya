/**
@file simplePBR.fx
@brief Contains simplified implementation of the shader_HOG_t_uv0bn-pbs_IBLenv shader program
that works in both Autodesk 3D Studio Max and Autodesk Maya
*/

/* Some tunning, set here to match Painter a little bit more */
static const float cg_PI = 3.141592666f;
static const float blikMultiplier = 15;
static const float mipMultiplier = 15;
static const float3 lightDirection = float3(1.3, .5, -1);

//------------------------------------
// Defines
//------------------------------------
// how many mip map levels should Maya generate or load per texture. 
// 0 means all possible levels
// some textures may override this value, but most textures will follow whatever we have defined here
// If you wish to optimize performance (at the cost of reduced quality), you can set NumberOfMipMaps below to 1
#define NumberOfMipMaps 0
#define ROUGHNESS_BIAS 0.005
#define EPSILON 10e-5f


#define _3DSMAX_SPIN_MAX 99999

static const float diffGamma = 2.2;

// general includes
#include "samplers.fxh"

// maxplay includes
#include "pbr_shader_ui.fxh"
#include "toneMapping.fxh"

// Maya includes
#include "mayaUtilities.fxh"

// max includes
#include "maxUtilities.fxh"

//------------------------------------
// Map Channels
//------------------------------------
#ifdef _3DSMAX_
MAXTEXCOORD0
#endif

//------------------------------------
// Samplers
//------------------------------------
// from samplers.fxh
// SamplerLinearClamp
SAMPLERMINMAGMIPLINEARCLAMP
// SamplerLinearWrap
SAMPLERMINMAGMIPLINEARWRAP
// SamplerShadowDepth
SAMPLERSTATESHADOWDEPTH
// SamplerCubeMap
SAMPLERCUBEMAP

// macro to include Vertex Elements
// from HOG_shader_ui.fxh macros
// vertexElementPosition
HOG_PROPERTY_VERTEX_ELEMENT_POSITION
// vertexElementColor
HOG_PROPERTY_VERTEX_ELEMENT_COLOR
// vertexElementUV
HOG_PROPERTY_VERTEX_ELEMENT_UV
// vertexElementNormal
HOG_PROPERTY_VERTEX_ELEMENT_NORMAL
// vertexElementBinormal
HOG_PROPERTY_VERTEX_ELEMENT_BINORMAL
// vertexElementTangent
HOG_PROPERTY_VERTEX_ELEMENT_TANGENT

//------------------------------------
// Textures
//------------------------------------
// string UIGroup = "Material Maps"; UI 050+
// from pbr.fxh macros
// baseColorMap:			Texture2D
HOG_MAP_BASECOLOR

// baseNormalMap:			Texture2D
HOG_MAP_BASENORMAL
// roughnessMap:			Texture2D
HOG_MAP_ROUGHNESS
// metalnessMap:			Texture2D		
HOG_MAP_METALNESS 

// These are PBR IBL env related texture inputs
// diffuseEnvTextureCube
HOG_CUBEMAP_IBLDIFF
// specularEnvTextureCube
HOG_CUBEMAP_IBLSPEC
// envLightingExp
HOG_ENVLIGHTING_EXP

//------------------------------------
// Per Frame constant buffer
//------------------------------------
cbuffer UpdatePerFrame : register(b0)
{
	float4x4 viewInv 			: ViewInverse < string UIWidget = "None"; > ;
	float4x4 view				: View < string UIWidget = "None"; > ;
	float4x4 prj				: Projection < string UIWidget = "None"; > ;
	float4x4 viewPrj			: ViewProjection < string UIWidget = "None"; > ;
	float4x4 worldViewInvTrans	: WorldViewInverseTranspose < string UIWidget = "None"; > ;

	// A shader may wish to do different actions when Maya is rendering the preview swatch (e.g. disable displacement)
	// This value will be true if Maya is rendering the swatch
	bool IsSwatchRender : MayaSwatchRender < string UIWidget = "None"; > = false;
}

//------------------------------------
// Per Object constant buffer
//------------------------------------
cbuffer UpdatePerObject : register(b1)
{
	float4x4	World				: World < string UIWidget = "None"; > ;
	float4x4	WorldView			: WorldView < string UIWidget = "None"; > ;
	float4x4	WorldIT 			: WorldInverseTranspose < string UIWidget = "None"; > ;
	float4x4	WorldViewProj		: WorldViewProjection < string UIWidget = "None"; > ;

	// these are per-object includes for this cBuffer
	// they come from pbr_shader_ui.fxh
	// "Material Properties" UI group
	// materialBumpIntensity:		scalar 0..1 (soft)
	HOG_PROPERTY_MATERIAL_BUMPINTENSITY

	// "Lighting Properties"
	// linearOutput:			bool
	HOG_PROPERTY_LINEAR_SPACE_LIGHTING
	// flipBackfaceNormals:			bool
	HOG_PROPERTY_FLIP_BACKFACE_NORMALS

} //end UpdatePerObject cbuffer

//------------------------------------
// Hardware Fog parameters
//------------------------------------
bool MayaHwFogEnabled : HardwareFogEnabled < string UIWidget = "None"; > = false;
int MayaHwFogMode : HardwareFogMode < string UIWidget = "None"; > = 0;
float MayaHwFogStart : HardwareFogStart < string UIWidget = "None"; > = 0.0f;
float MayaHwFogEnd : HardwareFogEnd < string UIWidget = "None"; > = 100.0f;
float MayaHwFogDensity : HardwareFogDensity < string UIWidget = "None"; > = 0.1f;
float4 MayaHwFogColor : HardwareFogColor < string UIWidget = "None"; > = { 0.5f, 0.5f, 0.5f , 1.0f };

//------------------------------------
// Vertex Shader
//------------------------------------
/**
@struct VsInput
@brief Input to the vertex unit from the vertex assembly unit
*/
struct vsInput
{
#ifdef _3DSMAX_
	float3 m_Position		: POSITION;
	float4 m_AlbedoRGBA     : COLOR0;
	float2 m_Uv0			: TEXCOORD0;
	float3 m_Normal			: NORMAL;
	float3 m_Tangent		: TANGENT;
	float3 m_Binormal		: BINORMAL;
	// missing:
	float4 m_VertexAO		: COLOR;
#else
	float3 m_Position		: POSITION;
	float4 m_AlbedoRGBA     : COLOR0;
	float4 m_VertexAO		: COLOR1;
	float2 m_Uv0			: TEXCOORD0;
	float3 m_Normal			: NORMAL;
	float3 m_Tangent		: TANGENT;
	float3 m_Binormal		: BINORMAL;
#endif
};

/**
@struct VsOutput
@brief Output from the vertex unit to later stages of GPU execution
*/
struct VsOutput
{
	float4 m_Position		: SV_POSITION;
	float4 m_albedoRGBA     : COLOR0;
	float4 m_VertexAO		: COLOR1;
	float2 m_Uv0			: TEXCOORD0;
	float4 m_WorldPosition	: TEXCOORD1_centroid;
	float4 m_View			: TEXCOORD2_centroid;
	float3x3 m_TWMtx		: TEXCOORD3_centroid;

	// should I convert these to float4!?
	float3 m_NormalW		: TEXCOORD6;
	float3 m_TangentW		: TEXCOORD7;
	float3 m_BinormalW		: TEXCOORD8;
};

/* Tools */

float3 RGBMDecode ( float4 rgbm, float hdrExp, float gammaExp ) 
{
    float3 upackRGBhdr = (rgbm.bgr * rgbm.a) * hdrExp;
    float3 rgbLin = pow(upackRGBhdr.rgb, gammaExp);
    return rgbLin;
}

/* BrDf: GGX */
float G1V(float dotNV, float k)
{
	return 1.0f/(dotNV*(1.0f-k)+k);
}

float LightingFuncGGX(float3 N, float3 V, float3 L, float roughness, float F0)
{
	float alpha = roughness*roughness;
	float3 H = normalize(V+L);
	float dotNL = saturate(dot(N,L));
	float dotLH = saturate(dot(L,H));
	float dotNH = saturate(dot(N,H));
	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float pi = 3.14159f;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
	D = alphaSqr/(pi * denom * denom);

	// F
	float dotLH5 = pow(1.0f-dotLH,5);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0f;
	float k2 = k*k;
	float invK2 = 1.0f-k2;
	vis = rcp(dotLH*dotLH*invK2 + k2);

	float specular = dotNL * D * F * vis;
	return specular;
}

/**
@brief Entry point to the vertex shader
@return VsOutput The results from the vertex shader passed to later GPU stages
@param[in] v Input from the vertex assembly unit
*/
VsOutput vsMain(vsInput v)
{
	VsOutput OUT = (VsOutput)0;

	OUT.m_Position = mul( float4( v.m_Position, 1.0f ), WorldViewProj );

	OUT.m_NormalW   = normalize( mul( v.m_Normal,   (float3x3)World));
	OUT.m_TangentW  = normalize( mul( v.m_Tangent,  (float3x3)World));
	OUT.m_BinormalW = normalize (mul( v.m_Binormal, (float3x3)World));

	// we pass vertices in world space
	OUT.m_WorldPosition = mul(float4(v.m_Position, 1), World);

	// Pass through texture coordinates
	// flip Y for Maya
#ifdef _MAYA_
	OUT.m_Uv0 = float2(v.m_Uv0.x, - v.m_Uv0.y);
#else
	OUT.m_Uv0 = v.m_Uv0;
#endif

	// Build the view vector and cache its length in W
	// pulling the view position in world space from the inverse view matrix 4th row
	OUT.m_View.xyz = viewInv[3].xyz - OUT.m_WorldPosition.xyz;
	OUT.m_View.w = length(OUT.m_View.xyz);
	// normalize
	OUT.m_View.xyz *= rcp(OUT.m_View.w);

	float3x3 tLocal;
	// Compose the tangent space to local space matrix
	OUT.m_TWMtx[0] = mul(v.m_Tangent, World);
	OUT.m_TWMtx[1] = mul(v.m_Binormal, World);
	OUT.m_TWMtx[2] = mul(v.m_Normal, World);

	// ZUP/YUP
	#ifdef _3DSMAX_
		OUT.m_View.xyz = float3(OUT.m_View.x, OUT.m_View.z, -OUT.m_View.y);
		OUT.m_WorldPosition = OUT.m_WorldPosition[0], OUT.m_WorldPosition[2], -OUT.m_WorldPosition[1];

		OUT.m_TWMtx[0] = float3(OUT.m_TWMtx[0][0], OUT.m_TWMtx[0][2], -OUT.m_TWMtx[0][1]);
		OUT.m_TWMtx[1] = float3(OUT.m_TWMtx[1][0], OUT.m_TWMtx[1][2], -OUT.m_TWMtx[1][1]);
		OUT.m_TWMtx[2] = float3(OUT.m_TWMtx[2][0], OUT.m_TWMtx[2][2], -OUT.m_TWMtx[2][1]);
	#endif

	return OUT;
}

//------------------------------------
// Pixel Shader
//------------------------------------
/**
@struct PsOutput
@brief Output that written to the render target
*/
struct PsOutput  // was APPDATA
{
	float4 m_Color			: SV_TARGET;
};

/**
@brief Entry point to the pixel shader
@return PsOutput Results written to the rendering target
@param[in] p Input from the interpolation units
*/
PsOutput pMain(VsOutput p, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	PsOutput o;

	// I think we need to POM before we clip?
	// 1) silohuette pom clips
	// 2) we can/should set up UV's before we start sampling textures?
	float2 baseUV = p.m_Uv0.xy;

	// store the worldToTangent matrix, but we will only calculate it where we use it
	float3x3 worldToTangent;

	// texture maps and such
	float3 baseColorTex = baseColorMap.Sample(SamplerLinearWrap, baseUV).rgb;

	// roughnessMap:			Texture2D
	float3 roughnessTex = roughnessMap.Sample(SamplerLinearWrap, baseUV).rgb;
	float pbrRoughness = 0.0f;  // store it here
	pbrRoughness = roughnessTex.g;

	// metalnessMap:			Texture2D
	float pbrMetalness = 0.0f;
	float3 metalnessTex = metalnessMap.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	pbrMetalness = metalnessTex.g;

	float3 normalMap = baseNormalMap.Sample(SamplerLinearWrap, baseUV).xyz;
	float3 normalLin = normalMap * 2 - 1; // ->Zero centered, (-1, 1)

	float3 bColorLin = pow(baseColorTex.rgb, 1.0f/diffGamma);

	float3 n = (normalLin.x * p.m_TWMtx[0] + normalLin.y * p.m_TWMtx[1]) + normalLin.z * p.m_TWMtx[2];
	
	// base color variant for metals
	float3 mColorLin = bColorLin.rgb * (1.0f - pbrMetalness);

	// reflection is incoming light
	float3 R = -reflect(p.m_View.xyz, n);
	// calc the mip level to fetch based on roughness
	
	// How blur blurred refl will be. Also: To mach look in painter value is multiplied for metals. Not sure why it works
	const float rMipCount = 8.0f + pbrMetalness * mipMultiplier;
	float roughMip = pbrRoughness * rMipCount;

	// Set up envmap values
	float4 diffEnvMap = diffuseEnvTextureCube.SampleLevel(SamplerCubeMap, n, 0.0f).rgba;
	float4 specEnvMap = specularEnvTextureCube.SampleLevel(SamplerCubeMap, R, roughMip).rgba;

	float3 specEnv = RGBMDecode(specEnvMap, envLightingExp, 1.0f/diffGamma);
	float3 diffEnv = RGBMDecode(diffEnvMap, envLightingExp, 1.0f/diffGamma);

	float specValue = lerp(0.02, 1, pbrMetalness);
	float3 spec = LightingFuncGGX(n, p.m_View.xyz, lightDirection, pbrRoughness, specValue); //Blink
	spec *=  blikMultiplier*lerp(1, pow(baseColorTex, 3), pbrMetalness);  //Color and power
	float fresnel = pow(1 - dot(p.m_View.xyz, n), 5);
	//Now fresnel reflections: lerp(1, baseColorTex*.9 + .1, pbrMetalness) was added to match look in painter.
	// It should not be there, but then results are weird withstrong normal maps: when mesh should reflect itself in real life
	spec.rgb += clamp(lerp(lerp(specValue, specValue*baseColorTex, pbrMetalness), lerp(1, baseColorTex*.9 + .1, pbrMetalness), fresnel),0,specValue) * pow(specEnv, 0.6)*2;

	// Finish:
	o.m_Color.rgb = (diffEnv * mColorLin.rgb);
	o.m_Color.rgb += spec;
	o.m_Color.w = 1;
	float3 result = o.m_Color.rgb;
	// Why does this work? It looks ok imo when linearSpaceOutput is on, but why I need to set gamma to 1/pow(diffGamma, 2) to make it look right with viewport cc?
	result = reinhardExp(result, 1.3, linearOutput?1.0f/diffGamma: 1/pow(diffGamma, 2));
	o.m_Color = float4(result.rgb, 1);
	return o;
}

#ifdef _MAYA_
/**
move these function into mayaUtilities.fxh
call them where they are needed
*/

//------------------------------------
// wireframe pixel shader
//------------------------------------
float4 fwire(VsOutput v) : SV_Target
{
	return float4(0, 0, 1, 1);
}


//------------------------------------
// pixel shader for shadow map generation
//------------------------------------
//float4 ShadowMapPS( float3 Pw, float4x4 shadowViewProj ) 
float4 ShadowMapPS(VsOutput v) : SV_Target
{

	float4 Pndc = mul(v.m_WorldPosition, viewPrj);

	// divide Z and W component from clip space vertex position to get final depth per pixel
	float retZ = Pndc.z / Pndc.w;

	retZ += fwidth(retZ);
	return retZ.xxxx;
}
#endif

// Techniques
//------------------------------------
/**
@brief The technique set up for the FX framework
*/

technique11 TessellationOFF
	<
		bool overridesDrawState = false;	// we do not supply our own render state settings

	#ifdef _MAYA_
		// Tells Maya that the effect supports advanced transparency algorithm,
		// otherwise Maya would render the associated objects simply by alpha
		// blending on top of other objects supporting advanced transparency
		// when the viewport transparency algorithm is set to depth-peeling or
		// weighted-average.
		bool supportsAdvancedTransparency = false;
	#endif
	>
	{
		pass P0
			<
			string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
			>
			{
				SetVertexShader(CompileShader(vs_5_0, vsMain()));
				SetPixelShader(CompileShader(ps_5_0, pMain()));
			}

	#ifdef _MAYA_
			pass pShadow
			<
			string drawContext = "shadowPass";	// shadow pass
			>
			{
				SetVertexShader(CompileShader(vs_5_0, vsMain()));
				SetPixelShader(CompileShader(ps_5_0, ShadowMapPS()));
			}
	#endif
	}

///////// VERTEX SHADING /////////////////////

///// TECHNIQUES /////////////////////////////
technique11 Main 
{
    pass p0 
	{
        	VertexShader = compile vs_5_0 vsMain();
        	PixelShader = compile ps_5_0 pMain();
	}
}
