#ifndef _PARTICLE_FUNCTION_HLSL_
#define _PARTICLE_FUNCTION_HLSL_

#include "../../Include/BaseDefine/CommonDefine.hlsl"



void ClipDisolve(real mask, real clipOffset)
{
    clip(mask - clipOffset);
}

void Disolve(real mask, real clipOffset)
{
    max( 0, mask - clipOffset);
}

float2 FlowOffsetFracUpdate(float2 uv, float2 Speed)
{
    return uv + frac(_Time.y * Speed);
}

#endif