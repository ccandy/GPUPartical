#ifndef _PARTICLE_DEFAULT_PASS_HLSL_
#define _PARTICLE_DEFAULT_PASS_HLSL_

#include "ParticleBuffer.hlsl"
#include "ParticleFunction.hlsl"

struct Attributes
{
    float4 vertex : POSITION;
    float4 color  : COLOR0;
    float4 uv0    : TEXCOORD0;
    float4 uv1    : TEXCOORD1;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS : SV_POSITION;
    real4 color      : COLOR0;
    real4 uv0        : TEXCOORD0;
    real4 uv1        : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
    
Varyings ParticleDefaultVert(Attributes v)
{
    Varyings o = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(UNITY_MATRIX_M, v.vertex);
        
    float4 posMVP   = mul(UNITY_MATRIX_VP, posWorld);
        
    o.positionCS    = posMVP;
    o.uv0.xy        = v.uv0.xy;//FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _BaseMap), v.uv0.zw);
    o.uv0.zw        = FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _MaskMap), v.uv1.xy);
    o.uv1.xy        = FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _MaskMap), v.uv1.zw);
    o.color         = v.color;

    return o;
}
    
real4 ParticleDefaultFrag(Varyings i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        
    real4 baseCol = SAMPLE_TEXTURE2D_DEF(_BaseMap, i.uv0.xy)*i.color*_Color;
    real4 maskCol = SAMPLE_TEXTURE2D_DEF(_MaskMap, i.uv0.zw);
        
    return baseCol;//baseCol*maskCol;
}
    
#endif
