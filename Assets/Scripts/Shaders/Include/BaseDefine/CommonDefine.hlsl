#ifndef _COMMON_DEFINE_HLSL_
#define	_COMMON_DEFINE_HLSL_

#include "PipelineCoreBase.hlsl"


#define TEXTURE2D_SAMPLE_PARAM_DEF(textureName) TEXTURE2D_PARAM( textureName, sampler##textureName)

#define TEXTURECUBE_SAMPLE_PARAM_DEF(textureName) TEXTURECUBE_PARAM( textureName, sampler##textureName)

#define TEXTURE3D_SAMPLE_PARAM_DEF(textureName) TEXTURE3D_PARAM( textureName, sampler##textureName)

#define TEXTURE_SAMPLE_ARGS_DEF(textureName)   \
	TEXTURE2D_ARGS(textureName, sampler##textureName) // 3D CUBE marco is the same way.

#define TEXTURE2D_DEF(textureName) \
	TEXTURE2D(textureName);\
	SAMPLER( sampler##textureName );

#define SAMPLE_TEXTURE2D_DEF(textureName, coord2) \
	SAMPLE_TEXTURE2D(textureName, sampler##textureName, coord2)

#define SAMPLE_TEXTURE2D_LOD_DEF(textureName, coord2, lod) \
	SAMPLE_TEXTURE2D_LOD(textureName, sampler##textureName, coord2, lod)

#define TEXTURE2D_ARRAY_DEF(textureName) \
	TEXTURE2D_ARRAY(textureName);\
	SAMPLER( sampler##textureName );

#define SAMPLE_TEXTURE2D_ARRAY_DEF(textureName, coord2, index) \
	SAMPLE_TEXTURE2D_ARRAY(textureName, sampler##textureName, coord2, index)

#define TEXTURECUBE_DEF(textureName) \
	TEXTURECUBE(textureName); \
	SAMPLER(sampler##textureName)

#define SAMPLE_TEXTURECUBE_DEF(textureName, coord3) \
	SAMPLE_TEXTURECUBE(textureName, sampler##textureName, coord3)                           

#define SAMPLE_TEXTURECUBE_LOD_DEF(textureName, coord3, lod) \
	SAMPLE_TEXTURECUBE_LOD(textureName, sampler##textureName, coord3, lod)

#define TEXTURE3D_DEF(textureName) \
	TEXTURE3D(textureName); \
	SAMPLER(sampler##textureName)

#define SAMPLE_TEXTURE3D_DEF(textureName)  \
	SAMPLE_TEXTURE3D(textureName, sampler##textureName, coord3)  

#if defined(UNITY_SINGLE_PASS_STEREO)
float2 TransformStereoScreenSpaceTex(float2 uv, float w)
{
    // TODO: RVS support can be added here, if Universal decides to support it
    float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
    return uv.xy * scaleOffset.xy + scaleOffset.zw * w;
}

float2 UnityStereoTransformScreenSpaceTex(float2 uv)
{
    return TransformStereoScreenSpaceTex(saturate(uv), 1.0);
}

#else

#define UnityStereoTransformScreenSpaceTex(uv) uv

#endif

#include "BaseInput.hlsl"

#endif