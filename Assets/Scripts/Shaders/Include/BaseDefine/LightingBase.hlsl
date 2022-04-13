#ifndef _LIGHTING_BASE_HLSL_
#define _LIGHTING_BASE_HLSL_

#include "PipelineCoreBase.hlsl"
#include "ShaderVariables.hlsl"
#include "SurfaceBase.hlsl"
#include "ShadowBase.hlsl"

struct Light
{
    half3   direction;
    half3   position;
    half3   color;
    half    attenuation;
};

Light GetMainLight()
{
    Light mainLight;
    
    mainLight.direction     = _MainLightDirection.xyz;
    mainLight.color         = _MainLightColor.xyz;
    mainLight.attenuation   = 1.0;
    
    return mainLight;
}

Light GetMainLight(float3 posWorld)
{
    Light mainLight;
    
    mainLight.direction     = _MainLightDirection.xyz;
    mainLight.color         = _MainLightColor.xyz;
    
    float fade = GetShadowFade(posWorld);
    
    float attenuation = MainLightRealtimeShadow(TransformWorldToShadowCoord(posWorld));
    
    mainLight.attenuation   = ApplyShadowFade( attenuation, fade);
    
    return mainLight;
}

real _DistanceAttenuation(real len, real range)
{
    real energe = max((range - len)/range, 0.0);
    return energe*energe;
}

Light SphereLightInit(Surface s, real3 lightPos, real radius, real4 color, real range)
{
    Light data = (Light) 0;
    
    real3 L = lightPos - s.posWorld;

    real len = length(L);

    real3 lightDir = L / len;

    real3 r = reflect(L, s.normalWorld);

    real3 centerToRay = L * r * r - L;

    real3 closestPoint = L + centerToRay * clamp(radius / length(centerToRay), 0.0, 1.0);

    data.direction = normalize(closestPoint);
    data.color = color.xyz;
    data.attenuation = _DistanceAttenuation( length(closestPoint - s.posWorld), range);

    return data;
}

Light PointLightInit(Surface s, real3 lightPos, real range, real3 color)
{
    Light data = (Light) 0;
    
    real3 L = lightPos - s.posWorld;
    real len = length(L);
    data.direction = L / len;
    data.color = color.xyz;
    data.attenuation = _DistanceAttenuation(len, range);

    return data;
}

#endif