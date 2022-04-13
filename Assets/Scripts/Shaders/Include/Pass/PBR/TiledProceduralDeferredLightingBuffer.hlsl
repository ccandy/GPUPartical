#ifndef _TILED_PROCEDURAL_DEFERRED_LIGHTING_BUFFER_HLSL_ 
#define _TILED_PROCEDURAL_DEFERRED_LIGHTING_BUFFER_HLSL_

#include "TiledDeferredLightingBuffer.hlsl"

StructuredBuffer<float4x4> _TileDataOfPointLights;

//// from HDRP
//float2 GetFullScreenTriangleTexCoord(uint vertexID)
//{
//#if UNITY_UV_STARTS_AT_TOP
//    return float2((vertexID << 1) & 2, 1.0 - (vertexID & 2));
//#else
//    return float2((vertexID << 1) & 2, vertexID & 2);
//#endif
//}

//2(5)   4
//
//0   1(3)
float2 GeTileQuadTexCoord(uint vertexID)
{
    const float2 uv[6] = {  float2(0,0),   float2(0,1.0), float2(1.0,0),   
                            float2(1.0,0), float2(1.0,1.0), float2(0,1.0),};
    
    return uv[vertexID%6];
}

int GeTileID(uint vertexID)
{    
    return vertexID / 6;
}

#endif