/**
@file shader_pbr.fxh
@brief Contains the Maya UI for setting material parameters for pbr shaders
*/

/**
@file 
@brief
@copyright
*/
#ifndef _SHADER_PBR_FXH_
#define _SHADER_PBR_FXH_ 

#include "propertyNames.fxh"

// ---------------------------------------------
// string UIGroup = "Material Maps"; UI 100+
// ---------------------------------------------
// #define HOG_GRP_MATERIAL_MAPS "Material Maps"

/**
@brief baseColor input for diffuse/albedo color shading calculations
*/


/**
@breif Specular F0 Map
Note:	IOR conversion into color space is:
		F0 = pow(abs((1.0f - IOR) / (1.0f + IOR)), 2.0f);
		pow(F0, 1/2.2333 ) * 255;
*/
// ---------------------------------------------
// string UIGroup = "Enrironment Maps"; UI 125+
// ---------------------------------------------
//#define HOG_GRP_ENV_LIGHTING "Enrironment Lighting"	

#define HOG_ENV_BOOL bool useEnvMaps						\
<															\
	string UIGroup = HOG_GRP_ENV_LIGHTING;					\
	string UIName = HOG_SCENE_USE_ENV;						\
	int UIOrder = 125;										\
> = true;

#define HOG_ENVMAP_TYPE int envMapType						\
<															\
	string UIGroup = HOG_GRP_ENV_LIGHTING;					\
	string UIWidget = "Slider";								\
	string UIFieldNames = "cubemap:LatLong[2D]";			\
	string UIName = HOG_SCENE_ENV_TYPE;						\
	int UIOrder = 126;										\
> = 0;

#define HOG_MAP_BRDF Texture2D brdfTextureMap				\
<															\
    string UIGroup = HOG_GRP_ENV_LIGHTING;					\
    string ResourceName = "";								\
    string UIWidget = "FilePicker";							\
    string UIName = HOG_SCENE_BRDF;							\
    string ResourceType = "2D";								\
    int mipmaplevels = 0;									\
    int UIOrder = 127;										\
>;

#define HOG_CUBEMAP_IBLDIFF TextureCube diffuseEnvTextureCube : environment	\
<															\
    string UIGroup = HOG_GRP_ENV_LIGHTING;					\
    string ResourceName = "";								\
    string UIWidget = "FilePicker";							\
    string UIName = HOG_SCENE_CUBE_IBLDIFF;					\
    string ResourceType = "Cube";							\
    int mipmaplevels = 0;									\
    int UIOrder = 128;										\
>;

#define HOG_CUBEMAP_IBLSPEC TextureCube specularEnvTextureCube : environment \
<															\
    string UIGroup = HOG_GRP_ENV_LIGHTING;					\
    string ResourceName = "";								\
    string UIWidget = "FilePicker";							\
    string UIName = HOG_SCENE_CUBE_IBLSPEC;					\
    string ResourceType = "Cube";							\
    int mipmaplevels = 0;									\
    int UIOrder = 129;										\
>;

#define HOG_LATLONG_IBLDIFF Texture2D diffuseEnvTextureLatlong : environment	\
<															\
    string UIGroup = HOG_GRP_ENV_LIGHTING;					\
    string ResourceName = "";								\
    string UIWidget = "FilePicker";							\
    string UIName = HOG_SCENE_LATLONG_IBLDIFF;				\
    string ResourceType = "Cube";							\
    int mipmaplevels = 0;									\
    int UIOrder = 130;										\
>;

#define HOG_LATLONG_IBLSPEC Texture2D specularEnvTextureLatlong : environment	\
<															\
    string UIGroup = HOG_GRP_ENV_LIGHTING;					\
    string ResourceName = "";								\
    string UIWidget = "FilePicker";							\
    string UIName = HOG_SCENE_LATLONG_IBLSPEC;				\
    string ResourceType = "Cube";							\
    int mipmaplevels = 0;									\
    int UIOrder = 131;										\
>;

#define HOG_ENVLIGHTING_EXP float envLightingExp	\
<													\
    string UIGroup = HOG_GRP_ENV_LIGHTING;			\
    string UIWidget = "Slider";						\
    float UIMin = 0.001;							\
    float UISoftMax = 100.000;						\
	float UIMax = 100.0f;	                        \
    float UIStep = 0.001;							\
    string UIName = HOG_SCENE_IBLEXP;				\
    int UIOrder = 132;								\
> = {5.0f};

// ---------------------------------------------
// string UIGroup = "Material Properties"; UI 150+
// ---------------------------------------------
//#define HOG_GRP_MAT_PROPS "Material Properties"

/**
@brief Marco to define base color material property for metalic workflow
*/
#define HOG_PROPERTY_MATERIAL_BASECOLOR float3 materialBaseColor		\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_BASECOLOR;								\
	string UIWidget = "ColorPicker";									\
	int UIOrder = 155;													\
> = { 0.6f, 0.6f, 0.6f};

/**
@brief Marco to define diffuse reflective material property
*/
#define HOG_PROPERTY_MATERIAL_DIFFUSE float3 materialDiffuse			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_DIFFUSE;								\
	string UIWidget = "ColorPicker";									\
	int UIOrder = 156;													\
> = { 0.6f, 0.6f, 0.6f};

/**
@brief Macro to define the anisotropicness for the surface
*/
#define HOG_PROPERTY_MATERIAL_ANISOTROPIC float materialAnisotropic		\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_ANISOTROPIC;							\
	string UIWidget = "Slider";											\
	float UIMin = 0.0;													\
	float UISMax = 1.0;													\
	float UIStep = 0.001;												\
	int UIOrder = 157;													\
> = 0.00f;

/**
@brief Macro to define the roughness for the surface
*/
#define HOG_PROPERTY_MATERIAL_ROUGHNESS float materialRoughness			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_ROUGHNESS;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.001;												\
	float UIMax = 0.999;												\
	float UIStep = 0.001;												\
	int UIOrder = 158;													\
> = 0.50f;

/**
@brief Macro to define the metalness of the surface
*/
#define HOG_PROPERTY_MATERIAL_METALNESS float materialMetalness			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_METALNESS;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.00;													\
	float UIMax = 1.0;													\
	float UIStep = 0.01;												\
	int UIOrder = 159;													\
> = 0.00f;

/**
@brief Macro to define the specularness of the surface
*/
#define HOG_PROPERTY_MATERIAL_SPECULAR float materialSpecular			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_SPECULAR;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.00;													\
	float UISoftMax = 1.0;												\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;												\
	int UIOrder = 160;													\
> = 1.00f;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_MATERIAL_SPECTINT	float materialSpecTint			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_SPECTINT;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.0;													\
	float UIMax = 1.0;													\
	float UIStep = 0.01;												\
	int UIOrder = 161;													\
> = 0.0f;

/**
@brief Macro to define the sheen amount of the surface
*/
#define HOG_PROPERTY_MATERIAL_SHEEN float materialSheen					\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_SHEEN;									\
	string UIWidget = "Slider";											\
	float UIMin = 0.00;													\
	float UISoftMax = 1.0;												\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;												\
	int UIOrder = 162;													\
> = 0.00f;

/**
@brief Macro to define the sheen tint amount of the surface
*/
#define HOG_PROPERTY_MATERIAL_SHEENTINT float materialSheentint			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_SHEENTINT;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.00;													\
	float UISoftMax = 1.0;												\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;												\
	int UIOrder = 163;													\
> = 0.00f;

/**
@brief Macro to define the clearcoat amount of the surface
*/
#define HOG_PROPERTY_MATERIAL_CLEARCOAT float materialClearcoat			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_CLEARCOAT;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.00;													\
	float UISoftMax = 1.0;												\
	float UIStep = 0.01;												\
	int UIOrder = 164;													\
> = 0.00f;

/**
@brief Macro to define the clearcoat tint amount of the surface
*/
#define HOG_PROPERTY_MATERIAL_CLEARCOATGLOSS float materialClearcoatGloss	\
<																			\
	string UIGroup = HOG_GRP_MAT_PROPS;										\
	string UIName = HOG_MATERIAL_CLEARCOATGLOSS;							\
	string UIWidget = "Slider";												\
	float UIMin = 0.00;														\
	float UISoftMax = 1.0;													\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;													\
	int UIOrder = 165;														\
> = 0.00f;

/**
@brief Macro to define the emissive color of the surface
*/
#define HOG_PROPERTY_MATERIAL_EMISSIVE	float3 materialEmissive			\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_MATERIAL_EMISSIVE;								\
	string UIWidget = "ColorPicker";									\
	int UIOrder = 166;													\
> = {0.0f, 0.0f, 0.0f};

/**
@brief Macro to define the emissive intensity
*/
#define HOG_PROPERTY_MATERIAL_EMISSIVEINT float materialEmissiveIntensity	\
<																			\
	string UIGroup = HOG_GRP_MAT_PROPS;										\
	string UIName = HOG_MATERIAL_EMISSIVEINT;								\
	string UIWidget = "Slider";												\
	float UIMin = 0.00;														\
	float UISoftMax = 3.0;													\
	float UIStep = 0.01;													\
	int UIOrder = 167;														\
> = 0.00f;

/**
@brief Macro to define surface IOR value

	Note:	IOR conversion into color space is:
			F0 = pow(abs((1.0f - IOR) / (1.0f + IOR)), 2.0f);
			pow(F0, 1/2.2333 ) * 255;

Various Material IOR values
https://pixelandpoly.com/ior.html

*/
/**
@brief Macro to define the height of the normal bump
*/
#define HOG_PROPERTY_MATERIAL_BUMPINTENSITY float materialBumpIntensity		\
<																			\
	string UIGroup = HOG_GRP_MAT_PROPS;										\
	string UIName = HOG_MATERIAL_BUMPINTENSITY;								\
	string UIWidget = "Slider";												\
	float UISoftMin = 0.020;												\
	float UISoftMax = 1.0;													\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;													\
	int UIOrder = 169;														\
> = 1.00f;


/**
@brief Macro to define switch for vertex color0, albedo RGBA
*/
#define HOG_PROPERTY_USE_VERTEX_C0_RGBA bool useVertexC0_RGBA				\
<																			\
	string UIGroup = HOG_GRP_MAT_PROPS;										\
	string UIName = HOG_USE_VERTEX_C0_RGBA;									\
	int UIOrder = 172;														\
> = false;

/**
@brief Macro to define Has Vertex Alpha for use with opacity
*/
#define HOG_PROPERTY_HAS_VERTEX_ALPHA bool hasVertexAlpha				\
<																		\
	string UIGroup = HOG_GRP_MAT_PROPS;									\
	string UIName = HOG_HAS_VERTEX_ALPHA;								\
	int UIOrder = 173;													\
> = false;

/**
@brief Macro to define switch for vertex color1, AO
*/
#define HOG_PROPERTY_USE_VERTEX_C1_AO bool useVertexC1_AO					\
<																			\
	string UIGroup = HOG_GRP_MAT_PROPS;										\
	string UIName = HOG_USE_VERTEX_C1_AO;									\
	int UIOrder = 174;														\
> = false;

// ---------------------------------------------
// string UIGroup = "Parallax Occlusion"; UI 190+
// ---------------------------------------------
//#define HOG_GRP_PARA_OCC "Parallax Occlusion"

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_USEPOM bool useParallaxOcclusionMapping	\
<																		\
	string UIGroup = HOG_GRP_PARA_OCC;									\
	string UIName = HOG_MATERIAL_USEPOM;								\
	int UIOrder = 190;													\
> = false;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMHEIGHTSCALE float materialPomHeightScale	\
<																			\
	string UIGroup = HOG_GRP_PARA_OCC;										\
	string UIName = HOG_MATERIAL_POMSCALE;									\
	string UIWidget = "Slider";												\
	float UIMin = 0.001;													\
	float UISoftMax = 1.0;													\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;													\
	int UIOrder = 191;														\
> = 1.00f;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_USEPOMSHDW bool usePOMselfShadow			\
<																		\
	string UIGroup = HOG_GRP_PARA_OCC;									\
	string UIName = HOG_MATERIAL_USEPOMSHDW;							\
	int UIOrder = 192;													\
> = false;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMMINSAMPLES int pomMinSamples				\
<																			\
	string UIGroup = HOG_GRP_PARA_OCC;										\
	string UIName = HOG_MATERIAL_POMMINSAMPLES;								\
	string UIWidget = "Slider";												\
	float UIMin = 1;														\
	float UISoftMax = 100;													\
	float UIMax = 100.0;	                        \
	float UIStep = 1;														\
	int UIOrder = 193;														\
> = 25;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMMAXSAMPLES int pomMaxSamples				\
<																			\
	string UIGroup = HOG_GRP_PARA_OCC;										\
	string UIName = HOG_MATERIAL_POMMAXSAMPLES;								\
	string UIWidget = "Slider";												\
	float UIMin = 1;														\
	float UISoftMax = 100;													\
	float UIMax = 100.0;	                        \
	float UIStep = 1;														\
	int UIOrder = 194;														\
> = 75;


/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMOCCOFFSET float selfOccOffset				\
<																			\
	string UIGroup = HOG_GRP_PARA_OCC;										\
	string UIName = HOG_MATERIAL_POMOCCOFFSET;								\
	string UIWidget = "Slider";												\
	float UIMin = 0.001;													\
	float UISoftMax = 1.0;													\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;													\
	int UIOrder = 195;														\
> = 0.09f;

/**
@brief to do
*/
#define HOG_PROPERTY_USEPOMSOFTSHDW	 bool usePOMsoftShadow				\
<																		\
	string UIGroup = HOG_GRP_PARA_OCC;									\
	string UIName = HOG_MATERIAL_USEPOMSOFTSHDW;						\
	int UIOrder = 196;													\
> = false;

/**
@Widget parallax shadow type pulldown
@brief provides a pull down menu, to select the type of parallax occlusion shadowing
*/
#define HOG_PROPERTY_MATERIAL_POMSHDWTYPE int parallaxOccShadowType		\
<																		\
	string UIGroup = HOG_GRP_PARA_OCC;									\
	string UIWidget = "Slider";											\
	string UIFieldNames = "none:simple:weighted:stencil";				\
	string UIName = HOG_MATERIAL_POMSHDWTYPE;							\
	int UIOrder = 197;													\
> = 1;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMOCCSHDWSTRENGTH float selfOccShadowStrength				\
<																							\
	string UIGroup = HOG_GRP_PARA_OCC;														\
	string UIName = HOG_MATERIAL_POMOCCSHDWSTR;												\
	string UIWidget = "Slider";																\
	float UIMin = 0.001;																	\
	float UIMax = 1.0;																		\
	float UIStep = 0.01;																	\
	int UIOrder = 198;																		\
> = 0.7f;

/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMSHDWMULTI float pomShadowMultiplier						\
<																							\
	string UIGroup = HOG_GRP_PARA_OCC;														\
	string UIName = HOG_MATERIAL_POMSHDWMULTI;												\
	string UIWidget = "Slider";																\
	float UIMin = 1.0;																		\
	float UISoftMax = 3.0;																	\
	float UIStep = 0.01;																	\
	int UIOrder = 199;																		\
> = 0.7f;


/**
@brief to do
*/
#define HOG_PROPERTY_MATERIAL_POMSOFTSHDWAMT float pomSoftShadowAmount		\
<																			\
	string UIGroup = HOG_GRP_PARA_OCC;										\
	string UIName = HOG_MATERIAL_POMSOFTSHDWAMT;							\
	string UIWidget = "Slider";												\
	float UIMin = 0.001;													\
	float UISoftMax = 1.0;													\
	float UIMax = 1.0;	                        \
	float UIStep = 0.01;													\
	int UIOrder = 200;														\
> = 1.0f;

// ---------------------------------------------
// string UIGroup = "Lighting Properties"; UI 300+
// ---------------------------------------------
//#define HOG_GRP_LIGHT_PROPS "Lighting Properties"

/**
@brief Marco to define ambient reflective material property
*/
#define HOG_PROPERTY_MATERIAL_AMBIENT float3 materialAmbient			\
<																		\
	string UIGroup = HOG_GRP_LIGHT_PROPS;								\
	string UIName = HOG_MATERIAL_AMBIENT;								\
	string UIWidget = "ColorPicker";									\
	int UIOrder = 300;													\
> = {0.1f, 0.1f, 0.1f};	

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_LINEAR_SPACE_LIGHTING bool linearOutput		\
<																		\
string UIGroup = HOG_GRP_LIGHT_PROPS;									\
string UIName = HOG_LINEAR;								\
int UIOrder = 301;														\
> = true;

/**
@brief flips back facing normals to improve lighting for things like sheets of hair or leaves
*/
#define HOG_PROPERTY_FLIP_BACKFACE_NORMALS bool flipBackfaceNormals		\
<																		\
string UIGroup = HOG_GRP_LIGHT_PROPS;									\
string UIName = HOG_FLIP_BACKFACE_NORMALS;								\
int UIOrder = 303;														\
> = true;																

// ---------------------------------------------
// string UIgroup = "Shadow"; UI 400+
// ---------------------------------------------
//#define HOG_GRP_SHADOW_PROPS "Shadow Properties"

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_IS_SHADOW_CASTER bool isShadowCaster				\
<																		\
	string UIGroup = HOG_GRP_SHADOW_PROPS;								\
	string UIName = HOG_IS_SHADOW_CASTER;								\
	int UIOrder = 400;													\
> = true;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_IS_SHADOW_RECEIVER bool isShadowReceiver			\
<																		\
	string UIGroup = HOG_GRP_SHADOW_PROPS;								\
	string UIName = HOG_IS_SHADOW_RECEIVER;								\
	int UIOrder = 401;													\
> = true;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_SHADOW_RANGE_AUTO	bool shadowRangeAuto			\
<																		\
	string UIGroup = HOG_GRP_SHADOW_PROPS;								\
	string UIName = HOG_SHADOW_RANGE_AUTO;								\
	int UIOrder = 402;													\
> = true;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_SHADOW_RANGE_MAX float shadowRangeMax				\
<																		\
	string UIGroup = HOG_GRP_SHADOW_PROPS;								\
	string UIName = HOG_SHADOW_RANGE_MAX;								\
	string UIWidget = "Slider";											\
	float UIMin = 0.0;													\
	float UISoftMax = 1000.0;											\
	float UIStep = 0.01;												\
	int UIOrder = 403;													\
> = 0.0f;

/**
@brief This offset allows you to fix any in-correct self shadowing caused by limited precision.
This tends to get affected by scene scale and polygon count of the objects involved.
*/
#define HOG_PROPERTY_SHADOW_DEPTH_BIAS float shadowDepthBias : ShadowMapBias	\
<																				\
	string UIGroup = HOG_GRP_SHADOW_PROPS;										\
	string UIName = HOG_SHADOW_DEPTH_BIAS;										\
	string UIWidget = "Slider";													\
	float UIMin = 0.000;														\
	float UISoftMax = 10.000;													\
	float UIMax = 10.0;	                        \
	float UIStep = 0.001;														\
	int UIOrder = 405;															\
> = {0.01f};																	

/**
@brief Shadow Intensity
*/
#define HOG_PROPERTY_SHADOW_MULTIPLIER float shadowMultiplier	\
<																\
	string UIGroup = HOG_GRP_SHADOW_PROPS;						\
	string UIName = HOG_SHADOW_MULTIPLIER;						\
	string UIWidget = "Slider";									\
	float UIMin = 0.000;										\
	float UIMax = 1.000;										\
	float UIStep = 0.001;										\
	int UIOrder = 406;											\
> = { 1.0f };													

/**
@brief use shadows
*/
#define HOG_PROPERTY_SHADOW_USE_SHADOWS bool useShadows		\
<															\
	string UIGroup = HOG_GRP_SHADOW_PROPS;					\
	string UIName = HOG_SHADOW_USE_SHADOWS;					\
	int UIOrder = 407;										\
> = false;													

// ---------------------------------------------
// string UIGroup = "HOG_GRP_ADV_PROPS"; UI 500+
// ---------------------------------------------
//#define HOG_GRP_ADV_PROPS "HOG_GRP_ADV_PROPS Properties"

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_POSITION int vertexElementPosition	\
<																		\
	string UIGroup = HOG_GRP_ADV_PROPS;									\
	string UIFieldNames = "Auto:16:32:";								\
	string UIName = HOG_VERTEX_ELEMENT_POSITION;						\
	float UIMin = 0;													\
	float UIMax = 2;													\
	float UIStep = 1;													\
	int UIOrder = 500;													\
> = 0;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_COLOR int vertexElementColor	\
<																	\
	string UIGroup = HOG_GRP_ADV_PROPS;								\
	string UIFieldNames = "Auto:16:32:";							\
	string UIName = HOG_VERTEX_ELEMENT_COLOR;						\
	float UIMin = 0;												\
	float UIMax = 2;												\
	float UIStep = 1;												\
	int UIOrder = 501;												\
> = 0;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_UV int vertexElementUV	\
<															\
	string UIGroup = HOG_GRP_ADV_PROPS;						\
	string UIFieldNames = "Auto:16:32:";					\
	string UIName = HOG_VERTEX_ELEMENT_UV;					\
	float UIMin = 0;										\
	float UIMax = 2;										\
	float UIStep = 1;										\
	int UIOrder = 502;										\
> = 0;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_NORMAL int vertexElementNormal		\
<																		\
	string UIGroup = HOG_GRP_ADV_PROPS;									\
	string UIFieldNames = "Auto:16:32:";								\
	string UIName = HOG_VERTEX_ELEMENT_NORMAL;							\
	float UIMin = 0;													\
	float UIMax = 2;													\
	float UIStep = 1;													\
	int UIOrder = 503;													\
> = 0;									

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_BINORMAL int vertexElementBinormal		\
<																			\
	string UIGroup = HOG_GRP_ADV_PROPS;										\
	string UIFieldNames = "Auto:16:32:";									\
	string UIName = HOG_VERTEX_ELEMENT_BINORMAL;							\
	float UIMin = 0;														\
	float UIMax = 2;														\
	float UIStep = 1;														\
	int UIOrder = 504;														\
> = 0;

/**
@brief Macro to define 
*/
#define HOG_PROPERTY_VERTEX_ELEMENT_TANGENT int vertexElementTangent	\
<																		\
	string UIGroup = HOG_GRP_ADV_PROPS;									\
	string UIFieldNames = "Auto:16:32:";								\
	string UIName = HOG_VERTEX_ELEMENT_TANGENT;							\
	float UIMin = 0;													\
	float UIMax = 2;													\
	float UIStep = 1;													\
	int UIOrder = 505;													\
> = 0;	

// ---------------------------------------------
// string UIGroup = "Engine | Scene Preview"; UI 600+
// ---------------------------------------------
//#define HOG_GRP_ENGN_PREV "Engine | Scene Preview"
/**
@brief the tone mapping bloom exponent
*/

/**
@brief Use the lights color value as the light/material specular color value
*/


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!


#define HOG_MAP_BASECOLOR Texture2D baseColorMap			\
<															\
	string UIGroup = HOG_GRP_MATERIAL_MAPS;					\
	string ResourceName = "";								\
	string UIWidget = "FilePicker";							\
	string UIName = HOG_BASECOLOR_MAP;						\
	string ResourceType = "2D";								\
	int mipmaplevels = NumberOfMipMaps;						\
	int UIOrder = 100;										\
	int UVEditorOrder = 1;									\
>;



// Roughness Map
#define HOG_MAP_ROUGHNESS Texture2D roughnessMap			\
<															\
	string UIGroup = HOG_GRP_MATERIAL_MAPS;					\
	string ResourceName = "";								\
	string UIWidget = "FilePicker";							\
	string UIName = HOG_ROUGHNESS_MAP;						\
	string ResourceType = "2D";									\
	int mipmaplevels = NumberOfMipMaps;						\
	int UIOrder = 102;										\
	int UVEditorOrder = 1;									\
>;
/**
@breif Metalness Map
*/
#define HOG_MAP_METALNESS Texture2D metalnessMap			\
<															\
	string UIGroup = HOG_GRP_MATERIAL_MAPS;					\
	string ResourceName = "";								\
	string UIWidget = "FilePicker";							\
	string UIName = "metalness";						\
	string ResourceType = "2D";								\
	int mipmaplevels = NumberOfMipMaps;						\
	int UIOrder = 103;										\
	int UVEditorOrder = 1;									\
>;
/**
@brief The NormalMap used to peturb normals for shading calculations
*/
#define HOG_MAP_BASENORMAL Texture2D baseNormalMap			\
<															\
	string UIGroup = HOG_GRP_MATERIAL_MAPS;					\
	string ResourceName = "";								\
	string UIWidget = "FilePicker";							\
	string UIName = HOG_NORMAL_MAP;							\
	string ResourceType = "2D";								\
	/** If mip maps exist in texture, Maya will load them.	\
	So user can pre-calculate and re-normalize mip maps		\
	for normal maps in .dds */								\
	int mipmaplevels = 0;									\
	int UIOrder = 101;										\
	int UVEditorOrder = 1;									\
>;

#endif // #ifndef _SHADER_PBR_FXH_