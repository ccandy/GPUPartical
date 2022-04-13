#ifndef _MIX_SHADING_HLSL_
#define _MIX_SHADING_HLSL_

#include "MixCommon.hlsl"

//// Kajiya Hair Shading in render monkey.
real3 CalHairShadingSpec(real3 lightColorFalloff, BxDFContext c, Surface s, real shift, real2 ShiftOffset, real2 shiftExp, real specMask, real3 halfDir)
{
    real3 T1 = ShiftTangent(s.tangentWorld, s.normalWorld, shift + ShiftOffset.x);
    real3 T2 = ShiftTangent(s.tangentWorld, s.normalWorld, shift + ShiftOffset.y);

    real3 specular = lightColorFalloff * s.baseColor * (HairSingleSpecularTerm(T1, halfDir, shiftExp.x) + HairSingleSpecularTerm(T2, halfDir, shiftExp.y)) * specMask;

    return specular;
}

//Cook - Microfacet specular F D G
// UE4 using Schlick-BackMann model

FDirectLighting MixLit(Surface surface, real3 N, real3 V, real NoL, Light l)
{
	BxDFContext context;
	InitBxDFContext(context, N, V, l.direction);

	real3 falloffColor = CalFalloffColor(context, NoL, l, surface.uv0);

	FDirectLighting Lighting;

	//Lighting.Diffuse = falloffColor * CalDiffuse(surface, context, NoL) * surface.occlusion;
	//Lighting.Diffuse = falloffColor * surface.diffColor * surface.occlusion;
	Lighting.Diffuse = falloffColor * CalDiffuse(surface, context, NoL);

	real3 specTerm = EnvBRDFApprox(surface.specColor, surface.roughness, context.NoV);

	Lighting.Specular =  falloffColor * SchlickBackMannSpec(surface, surface.roughness, specTerm, context, NoL, l)* surface.specOcclusion;
	//Lighting.Specular =  SchlickBackMannSpec(surface, surface.roughness, specTerm, context, NoL, l);
	//Lighting.Specular = SchlickBackMannSpec(surface, surface.roughness, specTerm, context, NoL, l);
	
	//Lighting.Specular = surface.bitangent;
	
	Lighting.Transmission = 0;

	return Lighting;
}

FDirectLighting BlinnLit(Surface surface, real3 N, real3 V, real NoL, Light l)
{
	BxDFContext context;
	InitBxDFContext(context, N, V, l.direction);

	real3 falloffColor = CalFalloffColor(context, NoL, l, surface.uv0);

	FDirectLighting Lighting;

	//Lighting.Diffuse = falloffColor * CalDiffuse(surface, context, NoL) * surface.occlusion;
	Lighting.Diffuse = falloffColor * surface.diffColor * surface.occlusion;
	//Lighting.Diffuse = CalDiffuse(surface, context, NoL);

	real3 specTerm = EnvBRDFApprox(surface.specColor, surface.roughness, context.NoV);

	Lighting.Specular = falloffColor * BlinnPhone(surface, surface.roughness, specTerm, context, NoL, l) * surface.specOcclusion;

	Lighting.Transmission = 0;

	return Lighting;
}
#endif