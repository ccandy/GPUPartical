#ifndef _TILED_DEFERRED_LIGHTING_BUFFER_HLSL_ 
#define _TILED_DEFERRED_LIGHTING_BUFFER_HLSL_

#include "../../BaseDefine/ConstDefine.hlsl"
#include "../../BaseDefine/CommonDefine.hlsl"
#include "../../BaseDefine/GBufferBase.hlsl"

#include "../../../../Pass/ShaderBuffer/TiledDeferredBuffer.hlsl"

TEXTURE2D_DEF(_DepthTexture);
TEXTURE2D_DEF(_GBuffer0);
TEXTURE2D_DEF(_GBuffer1);
TEXTURE2D_DEF(_GBuffer2);
TEXTURE2D_DEF(_GBuffer3);

float4x4 _ScreenToWorld;

int _DirectionalLight_Count;

StructuredBuffer<DirectionLightData>  _AdditionalDiretcionLightData;

StructuredBuffer<PointLightData>      _AdditionalPointLightData;

float4 _TileSize_ResolutionSize;

StructuredBuffer<TileLightingInfo>    _PointLightTileInfo;

StructuredBuffer<TileLightingCount>   _PointLightTileCount;

int _TiledPitchX;

int GetTileIndex(float2 uv)
{
    //int pitchX = (int)ceil(_TileSize_ResolutionSize.z / _TileSize_ResolutionSize.x);
    
    float2 tileUVSize = _TileSize_ResolutionSize.xy / _TileSize_ResolutionSize.zw;
    
    int y = floor(uv.y / tileUVSize.y);
    int x = floor(uv.x / tileUVSize.x);
    
    return y * _TiledPitchX + x;
}

#endif