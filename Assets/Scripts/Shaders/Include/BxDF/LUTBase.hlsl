#ifndef _LUT_BASE_HLSL_
#define _LUT_BASE_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
//#include "CommonBufferDef.hlsl"
#include "BxDFBaseFunction.hlsl"

#if defined(USE_LUT)

TEXTURE2D_DEF(_LUTTex);

TEXTURE2D_DEF(_CurvexTex);

real GetCurvex(real2 uv0)
{
	return SAMPLE_TEXTURE2D_DEF(_CurvexTex, uv0).r;
}

real3 CalScatterColor(real halfNoL, real falloff, real curvex)
{
	return SAMPLE_TEXTURE2D_DEF( _LUTTex, real2(halfNoL * falloff, curvex) ).rgb;
}

float3 CalLUTLightFalloff( Light l, real NoL, real2 uv0)
{
	real curvex = GetCurvex(uv0);

	real halfNoL = NoL > 0.0f ? NoL * 0.5 + 0.5 : 0.0f;

	return l.color * CalScatterColor( halfNoL, l.distanceAttenuation * l.shadowAttenuation, curvex);
}

float3 CalLUTLightFalloffSimple( Light l, real NoL, real2 uv0)
{
	real curvex = 0.5;

	real halfNoL = NoL > 0.0f ? NoL * 0.5 + 0.5 : 0.0f;

	return l.color * CalScatterColor( halfNoL, l.distanceAttenuation * l.shadowAttenuation, curvex);
}

#endif

#endif