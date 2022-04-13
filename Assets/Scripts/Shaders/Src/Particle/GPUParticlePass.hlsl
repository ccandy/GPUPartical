#ifndef _GPU_PARTICLE_PASS_HLSL_
#define _GPU_PARTICLE_PASS_HLSL_

#include "ParticleBuffer.hlsl"
#include "ParticleInstancedDefine.hlsl"
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
    float4 uv2       : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
    
Varyings GPUParticleVert(Attributes v, uint vIndex : SV_VertexID)
{
    Varyings o = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        
    float4 color;
    float4 posMVP;
        
    float isOutOfRange = 0.0;
           o.uv2           = 0.0;
#if defined(UNITY_INSTANCING_ENABLED)
    uint instanceID = UNITY_GET_INSTANCE_ID(v);

    float2 uvForData = InstanceIDToUV(instanceID, vIndex, isOutOfRange);
        
    o.uv2 = GetRealInstanceID( instanceID, vIndex);
    
    float4 posTime = GetVertex(v.vertex,uvForData);

    isOutOfRange *= (float)(posTime.w > 0.0);
    v.vertex.xyz = posTime.xyz;
   // o.uv2.xyz          = SAMPLE_TEXTURE2D_LOD_DEF( _InVelocityTexture, uvForData, 0).xyz;
 //   o.uv2.w = 1.0;
#endif
     
        
     //v.vertex.xyz = clamp(v.vertex.xyz,-60,60);
        
     float4 posWorld = v.vertex;
            
    //float4 posWorld = mul(UNITY_MATRIX_M, v.vertex); 
    color           = v.color*UNITY_MATRIX_M[3].w;
    posMVP          = mul(UNITY_MATRIX_VP, posWorld);
        
    posMVP          = lerp(float4(9999,9999,9999,1), posMVP, isOutOfRange);

    o.positionCS    = posMVP;
    o.uv0.xy        = v.uv0.xy;//FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _BaseMap), v.uv0.zw);
    o.uv0.zw        = FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _MaskMap), v.uv1.xy);
    o.uv1.xy        = FlowOffsetFracUpdate(TRANSFORM_TEX(v.uv0.xy, _MaskMap), v.uv1.zw);
    o.color         = color;
   

    return o;
}
    
real4 GPUParticleFrag(Varyings i) : SV_Target
{        
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        
    real4 baseCol = SAMPLE_TEXTURE2D_DEF(_BaseMap, i.uv0.xy)*i.color*_Color;
    real4 maskCol = SAMPLE_TEXTURE2D_DEF(_MaskMap, i.uv0.zw);
        
    uint d = i.uv2.x;
        
   d = max(0,i.uv2.x - 40000);
   //d = min(d,10000);
        
    return baseCol*maskCol;//float4(d.xxx/10000,1.0);//float4( length(i.uv2.xyz).xxx/90,1.0);//
}

#endif