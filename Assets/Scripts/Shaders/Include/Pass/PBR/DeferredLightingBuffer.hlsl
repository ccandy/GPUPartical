#ifndef _DEFERRED_LIGHTING_BUFFER_HLSL_ 
#define _DEFERRED_LIGHTING_BUFFER_HLSL_

#include "../../BaseDefine/ConstDefine.hlsl"
#include "../../BaseDefine/CommonDefine.hlsl"
#include "../../BaseDefine/GBufferBase.hlsl"

TEXTURE2D_DEF(_DepthTexture);
TEXTURE2D_DEF(_GBuffer0);
TEXTURE2D_DEF(_GBuffer1);
TEXTURE2D_DEF(_GBuffer2);
TEXTURE2D_DEF(_GBuffer3);

float4x4 _ScreenToWorld;

#define DirectionalLight_MaxCountPerPass 8
#define PointLight_MaxCountPerPass 8

int    _DirectionalLight_Count;
real4 _DirectionalLight_Directions[DirectionalLight_MaxCountPerPass];
real4 _DirectionalLight_Colores[DirectionalLight_MaxCountPerPass];

int    _PointLight_Count;
real4 _PointLight_Positions[PointLight_MaxCountPerPass];
real4 _PointLight_Colores[PointLight_MaxCountPerPass];
real  _PointLight_Range[PointLight_MaxCountPerPass];

#endif