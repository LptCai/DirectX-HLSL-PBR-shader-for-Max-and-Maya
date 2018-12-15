/**
@file shader_HOG_t_uv0bn-pbs_IBLenv.fx
@brief Contains the Maya Implementation of the shader_HOG_t_uv0bn-pbs_IBLenv shader program
*/

// uncomment to force true for compiling in VS
//#define _MAYA_ 1

//------------------------------------
// Defines
//------------------------------------
// how many mip map levels should Maya generate or load per texture. 
// 0 means all possible levels
// some textures may override this value, but most textures will follow whatever we have defined here
// If you wish to optimize performance (at the cost of reduced quality), you can set NumberOfMipMaps below to 1

static const float cg_PI = 3.141592666f;

#define NumberOfMipMaps 0
#define ROUGHNESS_BIAS 0.005
#define TEMP_IOR 0.03
#define EPSILON 10e-5f
//#define saturate(value) clamp(value, 0.000001f, 1.0f)

#define _3DSMAX_SPIN_MAX 99999

#ifndef _MAYA_
#define _ZUP_		// Maya is Y up, 3dsMax is Z up
#endif

// general includes
#include "samplers.fxh"

// maxplay includes
#include "lighting.sif"
#include "pbr.sif"
#include "pbr_shader_ui.fxh"
#include "toneMapping.fxh"

// Maya includes
#include "mayaUtilities.fxh"
#include "mayaLightsShadowMaps.fxh"
#include "mayaLights.fxh"
#include "mayaLightsUtilities.fxh"

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
// SamplerBrdfLUT
SAMPLERBRDFLUT

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
// specularF0Map:			Texture2D
HOG_MAP_SPECF0 
// specularMap:				Texture2D
HOG_MAP_SPECULAR

// These are PBR IBL env related texture inputs
// brdfTextureMap
HOG_MAP_BRDF
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

	// If the user enables viewport gamma correction in Maya's global viewport rendering settings, the shader should not do gamma again
	bool MayaFullScreenGamma : MayaGammaCorrection < string UIWidget = "None"; > = false;
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

	//these are per-object includes for this cBuffer
	// they come from pbr_shader_ui.fxh
	// "Material Properties" UI group
	// materialSpecular				scalar 0..1
	HOG_PROPERTY_MATERIAL_SPECULAR
	// materialBumpIntensity:		scalar 0..1 (soft)
	HOG_PROPERTY_MATERIAL_BUMPINTENSITY
	// useVertexC0_RGBA:			bool
	HOG_PROPERTY_USE_VERTEX_C0_RGBA
	// useVertexC1_AO:				bool
	HOG_PROPERTY_USE_VERTEX_C1_AO

	// "Lighting Properties"
	// materialAmbient:				sRGB
	// this is the amount of ambient influence 3-channel
	//HOG_PROPERTY_MATERIAL_AMBIENT
	// linearSpaceLighting:			bool
	HOG_PROPERTY_LINEAR_SPACE_LIGHTING
	// flipBackfaceNormals:			bool
	HOG_PROPERTY_FLIP_BACKFACE_NORMALS

	// "Shadows"
	// isShadowCaster:				bool
	HOG_PROPERTY_IS_SHADOW_CASTER
	// isShadowReceiver:			bool
	HOG_PROPERTY_IS_SHADOW_RECEIVER
	// shadowRangeAuto:				bool
	HOG_PROPERTY_SHADOW_RANGE_AUTO
	// shadowRangeMax:				float 0..1000
	HOG_PROPERTY_SHADOW_RANGE_MAX
	// Maya shadow preview stuff
	// shadowDepthBias:				float 0..10
	HOG_PROPERTY_SHADOW_DEPTH_BIAS
	// shadowMultiplier:			scalar 0..1
	HOG_PROPERTY_SHADOW_MULTIPLIER
	// useShadows:					bool
	HOG_PROPERTY_SHADOW_USE_SHADOWS

	// gammaCorrectionValue:	float 2.2333
	HOG_PROPERTY_GAMMA_CORRECTION_VALUE
	// bloomExp:				float 1.6
	HOG_PROPERTY_BLOOM_EXP
	// useLightColorAsLightSpecularColor:	bool
	HOG_PROPERTY_USE_LIGHT_COLOR_AS_LIGHT_SPECULAR_COLOR
	// useApproxToneMapping:				bool
	//HOG_PROPERTY_USE_APPROX_TONE_MAPPING
	// useGammaCorrectShader:				bool
	HOG_PROPERTY_GAMMA_CORRECT_SHADER

	// these macros come from mayaUtilities.fxh
	// NormalCoordsysX
	MAYA_DEBUG_NORMALX
	// NormalCoordsysY
	MAYA_DEBUG_NORMALY
	// NormalCoordsysZ
	MAYA_DEBUG_NORMALZ

} //end UpdatePerObject cbuffer

  //------------------------------------
  // DEBUG
  //------------------------------------
  /**
  @Widget DebugMenu
  @brief provides a menu to the user for enabling debug modes supported by this fx file
  */

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
	float3 m_Position		: POSITION0;
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
/**
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
BrDf
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

// Cook-Torrance specular BRDF + diffuse
// Schlick's approximation of the fresnel term

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


	//OUT.eye = normalize(mul(World, v.m_Position) - mul(viewInv, float4(0,0,0,1))).xyz;

	OUT.m_Position = mul( float4( v.m_Position, 1.0f ), WorldViewProj );

	//OUT.m_NormalW = normalize(mul(v.m_Normal, WorldIT));
	OUT.m_NormalW   = normalize( mul( v.m_Normal,   (float3x3)World));
	OUT.m_TangentW  = normalize( mul( v.m_Tangent,  (float3x3)World));
	OUT.m_BinormalW = normalize (mul( v.m_Binormal, (float3x3)World));

	// we pass vertices in world space
	OUT.m_WorldPosition = mul(float4(v.m_Position, 1), World);

	if (useVertexC0_RGBA)
	{
		// Interpolate and ouput vertex color 0
		OUT.m_albedoRGBA.rgb = v.m_AlbedoRGBA.rgb;
		OUT.m_albedoRGBA.w = v.m_AlbedoRGBA.w;
	}

	// setup Gamma Corrention
	float gammaCexp = linearSpaceLighting ? gammaCorrectionValue : 1.0;

	// convert sRGB color per-vertex to linear?
	OUT.m_albedoRGBA.rgb = linearSpaceLighting ? pow(v.m_AlbedoRGBA.rgb, gammaCexp) : OUT.m_albedoRGBA.rgb;

	if (useVertexC1_AO)
	{
		// Interpolate and ouput vertex color 1
		OUT.m_VertexAO.rgb = v.m_VertexAO.rgb;
		OUT.m_VertexAO.w = v.m_VertexAO.w;
	}

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

	// Compose the tangent space to local space matrix
	float3x3 tLocal;
	tLocal[0] = v.m_Tangent;
	tLocal[1] = v.m_Binormal;
	tLocal[2] = v.m_Normal;

	// Calculate the tangent to world space matrix
	OUT.m_TWMtx = mul (tLocal, (float3x3)World );

	// world space to tangent matrix?
	//OUT.m_WTMtx = transpose(tLocal);

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
#ifdef _3DSMAX_
	FrontFace = !FrontFace;
#endif
	// I think we need to POM before we clip?
	// 1) silohuette pom clips
	// 2) we can/should set up UV's before we start sampling textures?
	
	// unabashed modification of:  https://github.com/hamish-milne/POMUnity/blob/master/Assets/ParallaxOcclusion.cginc
	// and: https://www.gamedev.net/articles/programming/graphics/a-closer-look-at-parallax-occlusion-mapping-r3262
	// with help from:  http://www.d3dcoder.net/Data/Resources/ParallaxOcclusion.pdf
	// To Do: Put all of this in a function and include file (after it is working)
	float2 baseUV = p.m_Uv0.xy;
	float2 pomSsUV = baseUV.xy;

	// Parallax Mapping
	// Parallax Releif Mapping
	// http://sunandblackcat.com/tipFullView.php?topicid=28

	// these are also later used in POM self-occlusion
	float lastSampledHeight = 1.0f;
	float zStepSize = 0.0f;
	float2 finalTexOffset = float2(0.0f, 0.0f);

	// store the worldToTangent matrix, but we will only calculate it where we use it
	float3x3 worldToTangent;

	// To Do: expose these in the UI
	// The mip level id for transitioning between the full computation
	// for parallax occlusion mapping and the bump mapping computation
	bool pomVisualizeLOD = false;
	int pomLODThreshold = 3;
	float2 pomTextureDimensions = float2(1024, 1024);
	float  minTexCoordDelta = 0.0f;
	float2 deltaTexCoords = float2(0.0f, 0.0f);

	// store gradients
	float2 dxSize = float2(0.0f, 0.0f);
	float2 dySize = float2(0.0f, 0.0f);
	float2 dx = float2(0.0f, 0.0f);
	float2 dy = float2(0.0f, 0.0f);

	// Compute the current gradients:
	float2 texCoordsPerSize = float2(baseUV.xy * pomTextureDimensions.xy);

	// Compute all 4 derivatives in x and y in a single instruction to optimize:
	float4(dxSize, dx) = ddx(float4(texCoordsPerSize, baseUV));
	float4(dySize, dy) = ddy(float4(texCoordsPerSize, baseUV));

	// Multiplier for visualizing the level of detail (see notes for 'nLODThreshold' variable
	// for how that is done visually)

	// Parallax Mapping and Self-Shadowing
	// // http://sunandblackcat.com/tipFullView.php?topicid=28

	// Silohuette Parallax Occlusion Mapping
	// POM clipping, this doesn't work ... and I don't know how to do it properly.
	//clip(baseUV);
	//clip(1.0f - baseUV);

	//if (baseUV.x < 0.0 || baseUV.x > 1.0 || baseUV.y < 0.0 || baseUV.y > 1.0)
	//{
		//discard;
	//}

	// texture maps and such
	//baseColor, need to fetch it now so we can clip against albedo alpha channel
	float4 baseColorTex = baseColorMap.Sample(SamplerLinearWrap, baseUV).rgba;

	// setup Gamma Corrention
	float gammaCorrectionExponent = linearSpaceLighting ? gammaCorrectionValue : 1.0f;

	// most textures in this shaders setup, are considered single channel
	// not sure what happens if say an sRGB image is loaded instead!

	// roughnessMap:			Texture2D
	float pbrRoughness = 0.0f;  // store it here
	// fetch the texture, hopefully this works with 3-channel sRGB and 1-channel linear (better validate)
	// in the case that it is a 3-channel DXT, we pull the green (highest bit-depth)!
	float3 roughnessTex = roughnessMap.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	// assume you want the value black (empty) unless a texture is mapped
	pbrRoughness = roughnessTex.g;
	// this lets you load a full-range map, then use the material override to scale the value
	pbrRoughness = lerp( 0.0f, pbrRoughness, 1);


	// metalnessMap:			Texture2D
	float pbrMetalness = 0.0f;
	float3 metalnessTex = metalnessMap.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	pbrMetalness = metalnessTex.g;

	// specularF0Map:			Texture2D
	// should I allow for colored f0?  <-- To Do
	float3 pbrSpecF0 = float3( 0.04f, 0.04f, 0.04f);  // most materials are this range
	float3 specF0Tex = specularF0Map.Sample(SamplerLinearWrap, baseUV.xy).rgb;
	if (specF0Tex.r > 0.0f | specF0Tex.g > 0.0f | specF0Tex.b > 0.0f)
		pbrSpecF0.rgb = specF0Tex.rgb;

	// specularMap:				Texture2D
	float pbrSpecAmount = 0.0f;
	float specAmountTex = specularMap.Sample(SamplerLinearWrap, baseUV.xy).x;
	if (specAmountTex > 0)
		pbrSpecAmount = specAmountTex;
	pbrSpecAmount = lerp(float(0.0f).xxx, pbrSpecAmount, materialSpecular);

	// Normal Map
	float3 normalRaw = (baseNormalMap.Sample(SamplerLinearWrap, baseUV).xyz * 2.0f) - 1.0f;

	// FIX UP all color values --> Linear
	// base color linear
	float3 bColorLin = pow(baseColorTex.rgb, gammaCorrectionExponent);

	// combine the linear vertex color RGB and the linear base color
	if (useVertexC0_RGBA)
		bColorLin.rgb *= p.m_albedoRGBA.rgb;

	// set up the vertex AO
	float3 vertAO = (1.0f, 1.0f, 1.0f);
	if (useVertexC1_AO)
		vertAO.rgb = p.m_VertexAO.rgb;

	// Calculate the normals with intensity and derive Z
	float3 nTS = float3(normalRaw.xy * materialBumpIntensity, sqrt(1.0 - saturate(dot(normalRaw.xy, normalRaw.xy))));

	// DEBUG controls for flipping any normal component in Maya
	// (needed to figure out proper directions for X|Y)
	// PLEASE leave for now
	if (NormalCoordsysX > 0)
		nTS.x = -nTS.x;
	if (NormalCoordsysY > 0)
		nTS.y = -nTS.y;
	if (NormalCoordsysZ > 0)
		nTS.z = -nTS.z;

	if (flipBackfaceNormals)
	{
		nTS = lerp(-nTS, nTS, FrontFace);
	}

	// Transform the normal into world space where the light data is
	// Normalize proper normal lengths after decoding dxt normals and creating Z
	float3 n = normalize(mul(nTS, p.m_TWMtx));

	// We'll use Maya's SSAO this is mainly here for reference in porting the data to engine
	//float ssao = ssaoTexture.Sample(ssaoSampler, p.m_Position.xy * targetDimensions.xy).x;
	// I have no idea if there is a way to retreive the viewport AO buffer
	// I think not, because I beleive it's applied as post processing
	float ssao = 1.0;  // REPLACED with constant, Maya applies it's own

	// For calculate lighting contribution per light type
	// diffuse : Resulting diffuse color
	float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	// specular : Resulting specular color
	float4 specular = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// base color variant for metals
	float3 mColorLin = bColorLin.rgb * (1.0f - pbrMetalness);

	// F0 : Specular reflection coefficient (this is a scalar, not a color value!)
	// non-metals are 3% reflective... approximately
	// if you were going to hard code something, this would be a good guess
	// float3 F0 = lerp(float3(0.03, 0.03, 0.03), mColorLin, pbrMetalness);
	// but some escoteric materials might have different rgb values for F0?

	// If we want to replace this with an F0 input texture
	// the conversion into color space is pow(F0, 1/2.2333 ) * 255;

	// but lets not hard code it!
	// IOR values: http://www.pixelandpoly.com/ior.html#C
	// More IOR:  http://forums.cgsociety.org/archive/index.php?t-513458.html
	// water has a IOR of 1.333, converted it's F0 is appox 0.02
	//float3 F0 = abs(pow((1.0f - materialIOR), 2.0f) / pow((1.0f + materialIOR), 2.0f));
	float3 F0 = float3( 0.0f, 0.0f, 0.0f );

	// if we are using texture data, override
	F0.rgb = pbrSpecF0.rgb;

	// Specular tint (from disney plausible)
	//float3 bColorLin = albedo.rgb; // pass in color already converted to linear

	// materialSpecular				scalar 0..1

	// luminance approx.
	float bClum = 0.3f * (float)bColorLin[0] + 0.6f * (float)bColorLin[1] + 0.1f * (float)bColorLin[2];
	// normalize lum. to isolate hue+sat
	float3 Ctint = bClum > 0.0f ? bColorLin / bClum : 1.0f.xxx;

	// calculate the colored specular F0
	float3 Cspec0 = lerp( (float)materialSpecular * F0.rgb, bColorLin.rgb, (float)pbrMetalness);

	// build variations of roughness
	float pbrRoughnessBiased = (float)pbrRoughness * (1.0f - ROUGHNESS_BIAS) + ROUGHNESS_BIAS;
	float roughA = pbrRoughness * pbrRoughness;
	float roughA2 = roughA * roughA;

	// build roughness biased
	float roughnessBiasedA = roughA * (1.0f - ROUGHNESS_BIAS) + ROUGHNESS_BIAS;
	float roughnessBiasedA2 = roughnessBiasedA * roughnessBiasedA;

	// This won't change per-light so calulate it outside of the loop
	//float NdotV = clamp(dot(n, p.m_View.xyz), 0.00001, 1.0);
	// constant to prevent NaN
	//float NdotV = max(dot(n, p.m_View.xyz), 1e-5);	
	// Avoid artifact - Ref: SIGGRAPH14 - Moving Frosbite to PBR
	float NdotV = abs( dot( n.xyz, p.m_View.xyz ) ) + EPSILON;

	// shadow storage
	float4 shadow = (1.0f, 1.0f, 1.0f, 1.0f);
	float selfOccShadow = 1.0;

	// Set up envmap values
	float3 diffEnvLin = (0.0f, 0.0f, 0.0f);
	float3 specEnvLin = (0.0f, 0.0f, 0.0f);
	float4 diffEnvMap = (0.0f, 0.0f, 0.0f, 0.0f);
	float4 specEnvMap = (0.0f, 0.0f, 0.0f, 0.0f);

	// reflection is incoming light
	float3 R = -reflect(p.m_View.xyz, n);
	// this probably should not be a constant!
	const float rMipCount = 9.0f;
	// calc the mip level to fetch based on roughness
	float roughMip = pbrRoughnessBiased * rMipCount;

	// load brdf lookup
	brdfMap = GGXDistribution(NdotV, pbrRoughnessBiased);
	
	float offset = 0.05f;
	float3 refractedColor;

	// load cubemaps
	diffEnvMap = diffuseEnvTextureCube.SampleLevel(SamplerCubeMap, n, 0.0f).rgba;
	specEnvMap = specularEnvTextureCube.SampleLevel(SamplerCubeMap, R, roughMip).rgba;

	// decode RGBM --> HDR
	diffEnvLin = RGBMDecode(diffEnvMap, envLightingExp, gammaCorrectionExponent).rgb;
	specEnvLin = RGBMDecode(specEnvMap, envLightingExp, gammaCorrectionExponent).rgb;

	// tinted specular verus colored specular for metalness
	float3 cSpecLin = lerp(Cspec0.rgb, bColorLin.rgb, pbrMetalness) * brdfMap.x + brdfMap.y;
	//float3 fcSpecLin = Specular_F_Roughness(cSpecLin, roughnessBiased, NdotV);

	diffuse.rgb += diffEnvLin;

	// Multiply the specular by colored specular and specular amount
	specular.rgb *= cSpecLin.rgb * materialSpecular;
	specEnvLin.rgb *= cSpecLin.rgb * materialSpecular;
	specular.rgb += specEnvLin;

	// ----------------------
	// FINAL COLOR AND ALPHA:
	// ----------------------
	// add the cumulative diffuse and specular
	//o.m_Color.xyz = (diffuse.xyz * base.xyz) + (specular.xyz * base.xyz);
	o.m_Color.rgb = (diffuse.rgb * mColorLin.rgb * vertAO * ssao);
	o.m_Color.rgb += (specular.rgb * bColorLin.rgb * vertAO * ssao);
	o.m_Color.w = 1;
	float3 result = o.m_Color.rgb * 1;

#ifdef _MAYA_
	// do gamma correction and tone mapping in shader:
	// "none:approx:linear:linearExp:reinhard:reinhardExp:HaarmPeterCurve:HaarmPeterCurveExp:uncharted2FilmicTonemapping:uncharted2FilmicTonemappingExp"
	if (!MayaFullScreenGamma)
	{
		result = reinhardExp(result, bloomExp, gammaCorrectionExponent).rgb;
	}
#endif

	// REAL return out...
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

//------------------------------------
// Notes
//------------------------------------
// Shader uses 'pre-multiplied alpha' as its render state and this Uber Shader is build to work in unison with that.
// Alternatively, in Maya, the dx11Shader node allows you to set your own render states by supplying the 'overridesDrawState' annotation in the technique

//------------------------------------
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

float4 k_d  
<
	string UIName = "pure color";
	string UIWidget = "Color";
> = float4( 1.0f, 1.0f, 1.0f, 1.0f );

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
