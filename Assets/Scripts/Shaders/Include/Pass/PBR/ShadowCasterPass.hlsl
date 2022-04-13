#ifndef _SHADOW_CASTER_PASS_HLSL_
#define _SHADOW_CASTER_PASS_HLSL_

#include "../../BaseDefine/ShadowBase.hlsl"
#include "../../BaseDefine/CommonDefine.hlsl"

#include "ShadowCasterBuffer.hlsl"

struct Attributes
{
	float4 vertex			: POSITION;
	float2 uv0				: TEXCOORD0;
	float3 normal			: NORMAL;
	float4 tangent			: TANGENT;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionProj   : TEXCOORD1;
    float4 positionCS   : SV_POSITION;
};

Varyings ShadowPassVert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
    output.positionCS = GetShadowPositionHClip(input.vertex, input.normal);
    output.positionProj = output.positionCS;
    return output;
}

half4 ShadowPassFrag(Varyings input) : SV_TARGET
{
 #if defined(_ALPHATEST_ON)
    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a * _BaseColor.a;
    clip(alpha - _Cutoff);
#endif
    return 0.0;
}



#endif