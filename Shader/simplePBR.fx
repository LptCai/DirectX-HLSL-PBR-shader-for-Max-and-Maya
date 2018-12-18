/**
@file simplePBR.fx
@brief Contains simplified implementation of the shader_HOG_t_uv0bn-pbs_IBLenv shader program
that works in both Autodesk 3D Studio Max and Autodesk Maya
*/

static const float cg_PI = 3.141592666f;

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

static const float DffGamma = 0.7;
static const float Gamma = 1;

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
HOG_MAP_BASECOLOR1
HOG_MAP_BASECOLOR2
HOG_MAP_BASECOLOR3
HOG_MAP_BASECOLOR4
HOG_MAP_BASECOLOR5

HOG_MAP_MASK1
HOG_MAP_MASK2
HOG_MAP_MASK3
HOG_MAP_MASK4
HOG_MAP_MASK5

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
	// materialAmbient:				sRGB
	// this is the amount of ambient influence 3-channel
	//HOG_PROPERTY_MATERIAL_AMBIENT
	// linearSpaceLighting:			bool
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
	//float3x3 m_WTMtx		: TEXCOORD8_centroid;

	// should I convert these to float4!?
	float3 m_NormalW		: TEXCOORD6;
	float3 m_TangentW		: TEXCOORD7;
	float3 m_BinormalW		: TEXCOORD8;
};

float3 diffMixer(float3 d0, float3 d1, float3 d2, float3 d3, float3 d4, float3 d5,
				 float m1, float m2, float m3, float m4, float m5)
{
	float budget = 1.0f;
	float3 result = 0.0f; 
	float alpha;
	alpha = min(budget, m1);
	if (alpha > 0.01)
	{
		result += d1*alpha;
		budget -= alpha;
	}
	if (budget < 0.01) { return result; }
	alpha = min(budget, m2);
	if (alpha > 0.01)
	{
		result += d2*alpha;
		budget -= alpha;
	}
	if (budget < 0.01) { return result; }
	alpha = min(budget, m3);
	if (alpha > 0.01)
	{
		result += d3*alpha;
		budget -= alpha;
	}
	if (budget < 0.01) { return result; }
	alpha = min(budget, m4);
	if (alpha > 0.01)
	{
		result += d4*alpha;
		budget -= alpha;
	}
	if (budget < 0.01) { return result; }
	alpha = min(budget, m5);
	if (alpha > 0.01)
	{
		result += d5*alpha;
		budget -= alpha;
	}
	if (budget < 0.01) { return result; }
	result += d0*budget;
	return result;
}

/**
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
BrDf
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

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
float GGXDistribution(float NdotH, float roughness)

    {
        float rough2 = roughness * roughness;
        float tmp =  (NdotH * rough2 - NdotH) * NdotH + 1;
        return rough2 / (tmp * tmp);
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
	tLocal[0] = mul(v.m_Tangent, World);
	tLocal[1] = mul(v.m_Binormal, World);
	tLocal[2] = mul(v.m_Normal, World);

	#ifdef _3DSMAX_
		OUT.m_View.xyz = float3(OUT.m_View.x, OUT.m_View.z, -OUT.m_View.y);
		OUT.m_WorldPosition = OUT.m_WorldPosition[0], OUT.m_WorldPosition[2], -OUT.m_WorldPosition[1];

		tLocal[0] = float3(tLocal[0][0], tLocal[0][2], -tLocal[0][1]);
		tLocal[1] = float3(tLocal[1][0], tLocal[1][2], -tLocal[1][1]);
		tLocal[2] = float3(tLocal[2][0], tLocal[2][2], -tLocal[2][1]);
	#endif
	//OUT.m_View.xyz = float3(OUT.m_View.z, OUT.m_View.z, OUT.m_View.z);

	// Calculate the tangent to world space matrix
	OUT.m_TWMtx = tLocal;

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

	// MAYA | MAX Stuff

	// HARDCODED
	float3 lightDirection = float3(1.3, .5, -1);
	// I think we need to POM before we clip?
	// 1) silohuette pom clips
	// 2) we can/should set up UV's before we start sampling textures?
	float2 baseUV = p.m_Uv0.xy;

	// store the worldToTangent matrix, but we will only calculate it where we use it
	float3x3 worldToTangent;

	// Multiplier for visualizing the level of detail (see notes for 'nLODThreshold' variable
	// for how that is done visually)

	// texture maps and such
	//baseColor, need to fetch it now so we can clip against albedo alpha channel
	float3 baseColorTex = baseColorMap.Sample(SamplerLinearWrap, baseUV).rgb;

	baseColorTex = diffMixer(baseColorTex, baseColorTex1, baseColorTex2, baseColorTex3, baseColorTex4,baseColorTex5,
	maskTex1, maskTex2, maskTex3, maskTex4, maskTex5);

	// most textures in this shaders setup, are considered single channel
	// not sure what happens if say an sRGB image is loaded instead!

	// roughnessMap:			Texture2D
	float pbrRoughness = 0.0f;  // store it here
	// fetch the texture, hopefully this works with 3-channel sRGB and 1-channel linear (better validate)
	// in the case that it is a 3-channel DXT, we pull the green (highest bit-depth)!
	float3 roughnessTex = roughnessMap.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	pbrRoughness = roughnessTex.g;

	// metalnessMap:			Texture2D
	float pbrMetalness = 0.0f;
	float3 metalnessTex = metalnessMap.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	pbrMetalness = metalnessTex.g;


	pbrRoughness = pow(pbrRoughness, 1.0f/Gamma);
	pbrMetalness = pow(pbrMetalness, 1.0f/Gamma);
	float3 normalMap = baseNormalMap.Sample(SamplerLinearWrap, baseUV).xyz;
	float3 normalLin = pow(normalMap, 1.0f/Gamma) * 2 - 1;

	// FIX UP all color values --> Linear
	// base color linear
	float3 bColorLin = pow(baseColorTex.rgb, 1.0f/DffGamma);

	// set up the vertex AO
	float3 vertAO = (1.0f, 1.0f, 1.0f);

	// Calculate the normals with intensity and derive Z
	float3 nTS = float3(normalLin.xy * materialBumpIntensity, sqrt(1.0 - saturate(dot(normalLin.xy, normalLin.xy))));

	if (flipBackfaceNormals)
	{
		nTS = lerp(-nTS, nTS, FrontFace);
	}

	// Transform the normal into world space where the light data is
	// Normalize proper normal lengths after decoding dxt normals and creating Z
	
	//float3 n = normalize(mul(nTS, p.m_TWMtx));
	//float3 x = nTS.x * float3(p.m_TWMtx[0]);
	float3 n = (normalLin.x * p.m_TWMtx[0] + normalLin.y * p.m_TWMtx[1]) + normalLin.z * p.m_TWMtx[2];

	// We'll use Maya's SSAO this is mainly here for reference in porting the data to engine
	//float ssao = ssaoTexture.Sample(ssaoSampler, p.m_Position.xy * targetDimensions.xy).x;
	// I have no idea if there is a way to retreive the viewport AO buffer
	// I think not, because I beleive it's applied as post processing
	float ssao = 1.0;  // REPLACED with constant, Maya applies it's own
	
	// base color variant for metals
	float3 mColorLin = bColorLin.rgb * (1.0f - pbrMetalness);

	// Specular tint (from disney plausible)
	//float3 bColorLin = albedo.rgb; // pass in color already converted to linear

	// luminance approx.
	float bClum = 0.3f * (float)bColorLin[0] + 0.6f * (float)bColorLin[1] + 0.1f * (float)bColorLin[2];

	// build variations of roughness
	float pbrRoughnessBiased = (float)pbrRoughness * (1.0f - ROUGHNESS_BIAS) + ROUGHNESS_BIAS;

	float3 hVec = normalize( p.m_View.xyz + lightDirection) ;
	// WEIRD CODE ALERT: 
	float hVecDotN = max(0,  dot( hVec, n.xyz ) ) + EPSILON;

	// shadow storage
	float4 shadow = (1.0f, 1.0f, 1.0f, 1.0f);
	float selfOccShadow = 1.0;

	// reflection is incoming light
	float3 R = -reflect(p.m_View.xyz, n);

	// this probably should not be a constant!
	const float rMipCount = 8.0f + pbrMetalness * 15;
	// calc the mip level to fetch based on roughness
	float roughMip = pbrRoughnessBiased * rMipCount;

	// Set up envmap values
	float3 diffEnvMap = diffuseEnvTextureCube.SampleLevel(SamplerCubeMap, n, 0.0f).rgba;
	float3 specEnvMap = specularEnvTextureCube.SampleLevel(SamplerCubeMap, R, roughMip).rgba;

	float3 specEnv = specEnvMap * envLightingExp;
	float3 diffEnv = diffEnvMap * envLightingExp;

	float specValue = lerp(0.02, bColorLin, pbrMetalness);
	float3 spec = LightingFuncGGX(n, p.m_View.xyz, lightDirection, pbrRoughnessBiased, specValue);
	float fresnel = pow(1 - dot(p.m_View.xyz, n), 5);
	spec.rgb += lerp(lerp(specValue, 1, fresnel), bColorLin, pbrMetalness) * specEnv;

	o.m_Color.rgb = (diffEnv * mColorLin.rgb * vertAO * ssao);
	o.m_Color.rgb += spec;
	o.m_Color.w = 1;
	float3 result = o.m_Color.rgb;
	
	result = uncharted2FilmicTonemappingExp(result, Gamma, 1.2);
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
