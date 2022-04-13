#ifndef _UNLIT_PASS_HLSL_
#define _UNLIT_PASS_HLSL_

#include "UnlitBuffer.hlsl"

struct Attributes
{
    float4 vertex : POSITION;
    float4 color  : COLOR0;
    float2 uv0 : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS : SV_POSITION;
    real2 uv         : TEXCOORD0;
    real4 color      : COLOR0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};


Varyings UnlitVert(Attributes v)
{
    Varyings o = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(UNITY_MATRIX_M, v.vertex);
        
    float4 posMVP   = mul(UNITY_MATRIX_VP, posWorld);
        
    o.positionCS    = posMVP;
    o.uv            = TRANSFORM_TEX(v.uv0, _BaseMap);
    o.color         = v.color;

    return o;
}

real4 UnlitFrag(Varyings i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    real4 col = SAMPLE_TEXTURE2D_DEF(_BaseMap, i.uv) * i.color * _BaseColor;

    return col;
}

#endif