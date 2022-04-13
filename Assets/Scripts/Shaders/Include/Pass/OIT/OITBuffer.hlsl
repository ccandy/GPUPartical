#ifndef _OIT_BUFFER_HLSL_
#define _OIT_BUFFER_HLSL_

#include "../../BaseDefine/ConstDefine.hlsl"
#include "../../BaseDefine/CommonDefine.hlsl"

CBUFFER_START(UnityPerMaterial)
real4 _BaseMap_ST;
real4 _BaseColor;
real  _Cutoff;
CBUFFER_END

TEXTURE2D_DEF(_BaseMap);
TEXTURE2D_DEF(_DepthTexture);
TEXTURE2D_DEF(_OITDepthTexture);


float2 GetScreenUVFromPosMVP(float4 positionCS)
{
    return positionCS.xy/_ScreenParams.xy;
}
    
float GetDepthFromDepthTexture(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD_DEF( _DepthTexture, screenUV, 0).r;
}

float GetOITDepthFromDepthTexture(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD_DEF( _OITDepthTexture, screenUV, 0).r;
}
    
real4 OITFirstPassCol(float4 posMVP, real4 finalCol)
{
    float2 screenUV = GetScreenUVFromPosMVP(posMVP);
    float d = GetDepthFromDepthTexture(screenUV);
        
#if UNITY_REVERSED_Z
    if ( posMVP.z <= d)
        discard;
    
    return 	step( d, posMVP.z) * finalCol;
#else
    if ( posMVP.z >= d)
        discard;
    
    return 	step( posMVP.z, d) * finalCol;
#endif
}
    
real4 OITSubPassCol(float4 posMVP, real4 finalCol)
{
    float2 screenUV = GetScreenUVFromPosMVP(posMVP);
    float OITDepth =  GetOITDepthFromDepthTexture(screenUV);
     
#if UNITY_REVERSED_Z
    if ( posMVP.z >= OITDepth)
        discard;
        
    float d = GetDepthFromDepthTexture(screenUV);    
    
    return 	step( d, posMVP.z) * finalCol;
#else
    if ( posMVP.z <= OITDepth)
        discard;
        
    float d = GetDepthFromDepthTexture(screenUV);    
    
    return 	step( posMVP.z, d) * finalCol;
#endif
}

#endif