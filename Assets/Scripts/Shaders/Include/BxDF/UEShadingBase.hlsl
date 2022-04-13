#ifndef _UE_SHADING_HLSL_
#define _UE_SHADING_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
#include "BxDFContext.hlsl"
#include "BxDFBaseFunction.hlsl"
#include "UEBasePhysicBxDF.hlsl"


// URP use Light instead
//struct FAreaLight
//{
//	real		SphereSinAlpha;
//	real		SphereSinAlphaSoft;
//	real		LineCosSubtended;
//
//	real3		FalloffColor;
//
//	//FRect		Rect;
//	//FRectTexture Texture;
//	//bool		bIsRect;
//};

//struct FShadowTerms
//{
//	real	SurfaceShadow;
//	real	TransmissionShadow;
//	real	TransmissionThickness;
//};

real New_a2(real a2, real SinAlpha, real VoH)
{
	return a2 + 0.25 * SinAlpha * (3.0 * sqrt(a2) + SinAlpha) / (VoH + 0.001);
	//return a2 + 0.25 * SinAlpha * ( saturate(12 * a2 + 0.125) + SinAlpha ) / ( VoH + 0.001 );
	//return a2 + 0.25 * SinAlpha * ( a2 * 2 + 1 + SinAlpha ) / ( VoH + 0.001 );
}

//real EnergyNormalization(inout real a2, real VoH, Light light)
//{
//	if (AreaLight.SphereSinAlphaSoft > 0)
//	{
//		// Modify Roughness
//		a2 = saturate(a2 + Pow2(AreaLight.SphereSinAlphaSoft) / (VoH * 3.6 + 0.4));
//	}
//
//	real Sphere_a2 = a2;
//	real Energy = 1;
//	if (AreaLight.SphereSinAlpha > 0)
//	{
//		Sphere_a2 = New_a2(a2, AreaLight.SphereSinAlpha, VoH);
//		Energy = a2 / Sphere_a2;
//	}
//
//	if (AreaLight.LineCosSubtended < 1)
//	{
//#if 1
//		real LineCosTwoAlpha = AreaLight.LineCosSubtended;
//		real LineTanAlpha = sqrt((1.0001 - LineCosTwoAlpha) / (1 + LineCosTwoAlpha));
//		real Line_a2 = New_a2(Sphere_a2, LineTanAlpha, VoH);
//		Energy *= sqrt(Sphere_a2 / Line_a2);
//#else
//		real LineCosTwoAlpha = AreaLight.LineCosSubtended;
//		real LineSinAlpha = sqrt(0.5 - 0.5 * LineCosTwoAlpha);
//		real Line_a2 = New_a2(Sphere_a2, LineSinAlpha, VoH);
//		Energy *= Sphere_a2 / Line_a2;
//#endif
//	}
//
//	return Energy;
//}

float GGX_Mobile_Simple(float Roughness, float NoH)
{
	float OneMinusNoHSqr = 1.0 - NoH * NoH;

	float a = Roughness * Roughness;
	float n = NoH * a;
	float p = a / (OneMinusNoHSqr + n * n);
	float d = p * p;
	return d;
}

float CalcSpecular(float Roughness, float NoH)
{
	return (Roughness*0.25 + 0.25) * GGX_Mobile_Simple(Roughness, NoH);
}

real3 SpecularGGX(real Roughness, real3 SpecularColor, BxDFContext Context, real NoL, Light light)
{
	real a2 = Pow4(Roughness);
	//real Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

	// Generalized microfacet specular
	real D = _D_GGX(a2, Context.NoH);// *Energy;
	
	real Vis = Vis_SmithJointApprox(a2, Context.NoV, NoL);

	real3 F = _F_Schlick(SpecularColor, Context.VoH);

	return (D * Vis) * F;
}

// Just for test.
real3 SpecularGGXOrign(real Roughness, real3 SpecularColor, BxDFContext Context, real NoL, Light light)
{
	real a2 = Pow4(Roughness);
	//real Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

	// Generalized microfacet specular
	real D = _D_GGX(a2, Context.NoH);// *Energy;

	real Vis = Vis_Smith(a2, Context.NoV, NoL);

	real3 F = _F_Schlick(SpecularColor, Context.VoH);

	return (D * Vis) * F;
}

real3 DualSpecularGGX(real AverageRoughness, real Lobe0Roughness, real Lobe1Roughness, real LobeMix, real3 SpecularColor, BxDFContext Context, real NoL, Light light)
{
	real AverageAlpha2 = Pow4(AverageRoughness);
	real Lobe0Alpha2 = Pow4(Lobe0Roughness);
	real Lobe1Alpha2 = Pow4(Lobe1Roughness);

	//real Lobe0Energy = EnergyNormalization(Lobe0Alpha2, Context.VoH, AreaLight);
	//real Lobe1Energy = EnergyNormalization(Lobe1Alpha2, Context.VoH, AreaLight);

	// Generalized microfacet specular
	real D = lerp(_D_GGX(Lobe0Alpha2, Context.NoH)/* * Lobe0Energy*/, _D_GGX(Lobe1Alpha2, Context.NoH) /** Lobe1Energy*/, LobeMix);
	real Vis = Vis_SmithJointApprox(AverageAlpha2, Context.NoV, NoL); // Average visibility well approximates using two separate ones (one per lobe).
	real3 F = _F_Schlick(SpecularColor, Context.VoH);

	return (D * Vis) * F;
}

struct FDirectLighting
{
	real3	Diffuse;
	real3	Specular;
	real3	Transmission;
};

#endif