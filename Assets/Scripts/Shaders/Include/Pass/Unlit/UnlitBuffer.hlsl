#ifndef _UNLIT_BUFFER_HLSL_
#define _UNLIT_BUFFER_HLSL_

#include "../../BaseDefine/ConstDefine.hlsl"
#include "../../BaseDefine/CommonDefine.hlsl"


CBUFFER_START(UnityPerMaterial)
real4 _BaseMap_ST;
real4 _BaseColor;
real _Cutoff;
CBUFFER_END

TEXTURE2D_DEF(_BaseMap);

#endif