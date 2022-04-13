#ifndef _EARLY_Z_PASS_HLSL_
#define _EARLY_Z_PASS_HLSL_

#include "EarlyZBuffer.hlsl"

struct Attributes
{
	float4 vertex			: POSITION;
	float2 uv0				: TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	real4 positionCS	: SV_POSITION;
	real2 uv			: TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

Varyings EarlyZPassVert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    float4 posWorld     = mul(UNITY_MATRIX_M, input.vertex);
    output.positionCS   = mul(UNITY_MATRIX_VP, posWorld);
        
    output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);

    return output;
}

half4  EarlyZPassFrag(Varyings input) : SV_TARGET
{
 #if defined(_ALPHATEST_ON)
    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a * _BaseColor.a;
    clip(alpha - _Cutoff);
#endif
    return 0.0;//float4(EncodeFloatRGBA(input.positionCS.z));
}

#endif