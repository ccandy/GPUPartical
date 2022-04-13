#ifndef _PARTICLE_BUFFER_HLSL_
#define _PARTICLE_BUFFER_HLSL_

#include "../../Include/BaseDefine/ConstDefine.hlsl"
#include "../../Include/BaseDefine/CommonDefine.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"


CBUFFER_START(UnityPerMaterial)
    float4  _Color;
    float4  _TextureSampleAdd;
    float4  _ClipRect;
    float4  _BaseMap_ST;
    float4  _MaskMap_ST;
CBUFFER_END

CBUFFER_START(UnityPerParticleEmitterColor)
    float4  _GradientColor[8];
    float   _GradientColorTime[8];
CBUFFER_END

TEXTURE2D_DEF(_BaseMap);
TEXTURE2D_DEF(_MaskMap);
TEXTURE2D_DEF(_NoiseMap);

#endif