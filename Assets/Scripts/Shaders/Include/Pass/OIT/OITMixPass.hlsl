#ifndef _OIT_MIX_PASS_HLSL_
#define _OIT_MIX_PASS_HLSL_

#include "OITMixBuffer.hlsl"

struct Attributes
{
    float4 vertex       : POSITION;
    float2 uv           : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS    : SV_POSITION;
    float2 screenUV      : TEXCOORD0;
};

Varyings OITMixVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    
    output.screenUV = UnityStereoTransformScreenSpaceTex(input.uv);
    output.positionCS = ComputeClipSpacePosition(input.uv, 0);
    
    return output;
}

half4 OITMixFragment(Varyings i) : SV_Target
{
    real4 OitBlendColor0 = SAMPLE_TEXTURE2D_LOD_DEF( _OITTarget,         i.screenUV, 0);
     //return OitBlendColor0;
	real4 OitBlendColor1 = SAMPLE_TEXTURE2D_LOD_DEF(_OITSubPassTarget0, i.screenUV, 0);
	real4 OitBlendColor2 = SAMPLE_TEXTURE2D_LOD_DEF(_OITSubPassTarget1, i.screenUV, 0);
	real4 OitBlendColor3 = SAMPLE_TEXTURE2D_LOD_DEF(_OITSubPassTarget2, i.screenUV, 0);
    
    
	real4 col;
	col.rgb = lerp(OitBlendColor3.rgb * OitBlendColor3.a, OitBlendColor2.rgb, OitBlendColor2.a);
	col.rgb = lerp(col.rgb, OitBlendColor1.rgb, OitBlendColor1.a);
	col.rgb = lerp(col.rgb, OitBlendColor0.rgb, OitBlendColor0.a);
    
	col.a = 1.0 - (1.0 - OitBlendColor3.a) * (1.0 - OitBlendColor2.a) * (1.0 - OitBlendColor1.a) * (1.0 - OitBlendColor0.a);
    
	return col;
}

#endif