#ifndef _UE_BASE_PHYSIC_BXDF_HLSL_
#define	_UE_BASE_PHYSIC_BXDF_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
#include "BxDFContext.hlsl"
#include "BxDFBaseFunction.hlsl"

// Physically based shading model
// parameterized with the below options

// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
// Vis = G / (4*NoL*NoV)

real3 Diffuse_Lambert(real3 DiffuseColor)
{
    return DiffuseColor;// * M_INV_PI;
}

// [Burley 2012, "Physically-Based Shading at Disney"]
real3 Diffuse_Burley(real3 DiffuseColor, real Roughness, real NoV, real NoL, real VoH)
{
	real FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	real FdV = 1 + (FD90 - 1) * Pow5(1 - NoV);
	real FdL = 1 + (FD90 - 1) * Pow5(1 - NoL);
    return DiffuseColor * (FdV * FdL); // * M_INV_PI;
}

// [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
real3 Diffuse_OrenNayar(real3 DiffuseColor, real Roughness, real NoV, real NoL, real VoH)
{
	real a = Roughness * Roughness;
	real s = a;// / ( 1.29 + 0.5 * a );
	real s2 = s * s;
	real VoL = 2 * VoH * VoH - 1;      // double angle identity
	real Cosri = VoL - NoV * NoL;
	real C1 = 1 - 0.5 * s2 / (s2 + 0.33);
	real C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * (Cosri >= 0 ? rcp(max(NoL, NoV)) : 1);
    return DiffuseColor * (C1 + C2) * (1 + Roughness * 0.5); // * M_INV_PI;

}

// [Gotanda 2014, "Designing Reflectance Models for New Consoles"]
real3 Diffuse_Gotanda(real3 DiffuseColor, real Roughness, real NoV, real NoL, real VoH)
{
	real a = Roughness * Roughness;
	real a2 = a * a;
	real F0 = 0.04;
	real VoL = 2 * VoH * VoH - 1;      // double angle identity
	real Cosri = VoL - NoV * NoL;
#if 1
	real a2_13 = a2 + 1.36053;

	real OneMinusNov = max(0, 1 - NoV);

	real Fr = ( 1 - ( 0.542026*a2 + 0.303573*a ) / a2_13 ) * ( 1 - pow( OneMinusNov, 5 - 4*a2 ) / a2_13 ) * ( ( -0.733996*a2*a + 1.50912*a2 - 1.16402*a ) * pow( OneMinusNov, 1 + rcp(39*a2*a2+1) ) + 1 );
	//real Fr = ( 1 - 0.36 * a ) * ( 1 - pow( 1 - NoV, 5 - 4*a2 ) / a2_13 ) * ( -2.5 * Roughness * ( 1 - NoV ) + 1 );
	real Lm = ( max( 1 - 2*a, 0 ) * ( 1 - Pow5( 1 - NoL ) ) + min( 2*a, 1 ) ) * ( 1 - 0.5*a * (NoL - 1) ) * NoL;
	real Vd = ( a2 / ( (a2 + 0.09) * (1.31072 + 0.995584 * NoV) ) ) * ( 1 - pow( 1 - NoL, ( 1 - 0.3726732 * NoV * NoV ) / ( 0.188566 + 0.38841 * NoV ) ) );
	real Bp = Cosri < 0 ? 1.4 * NoV * NoL * Cosri : Cosri;
	real Lr = (21.0 / 20.0) * (1 - F0) * ( Fr * Lm + Vd + Bp );
    return DiffuseColor * Lr; // * M_INV_PI;
#else
	real a2_13 = a2 + 1.36053;
	real Fr = (1 - (0.542026 * a2 + 0.303573 * a) / a2_13) * (1 - pow(1 - NoV, 5 - 4 * a2) / a2_13) * ((-0.733996 * a2 * a + 1.50912 * a2 - 1.16402 * a) * pow(1 - NoV, 1 + rcp(39 * a2 * a2 + 1)) + 1);
	real Lm = (max(1 - 2 * a, 0) * (1 - Pow5(1 - NoL)) + min(2 * a, 1)) * (1 - 0.5 * a + 0.5 * a * NoL);
	real Vd = (a2 / ((a2 + 0.09) * (1.31072 + 0.995584 * NoV))) * (1 - pow(1 - NoL, (1 - 0.3726732 * NoV * NoV) / (0.188566 + 0.38841 * NoV)));
	real Bp = Cosri < 0 ? 1.4 * NoV * Cosri : Cosri / max(NoL, 1e-8);
	real Lr = (21.0 / 20.0) * (1 - F0) * (Fr * Lm + Vd + Bp);
	return DiffuseColor * Lr; // * M_INV_PI;
#endif
}

// [Blinn 1977, "Models of light reflection for computer synthesized pictures"]
real D_Blinn(real a2, real NoH)
{
	real n = 2 / a2 - 2;
	return (n + 2) / (2 * PI) * PhongShadingPow(NoH, n);        // 1 mad, 1 exp, 1 mul, 1 log
}

// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
real D_Beckmann(real a2, real NoH)
{
	real NoH2 = NoH * NoH;
	return exp((NoH2 - 1) / (a2 * NoH2)) / (PI * a2 * NoH2 * NoH2);
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
real _D_GGX(real a2, real NoH)
{
	real d = (NoH * a2 - NoH) * NoH + 1;   // 2 mad
	real divV = PI * d * d;
	
	return divV > 0.0 ? a2 / divV : 0;               // 4 mul, 1 rcp
}

// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
real _D_GGXaniso(real ax, real ay, real NoH, real3 H, real3 X, real3 Y)
{
	real XoH = dot(X, H);
	real YoH = dot(Y, H);
	real d = XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay) + NoH * NoH;
	return 1 / (PI * ax * ay * d * d);
}

real Vis_Implicit()
{
	return 0.25;
}

// [Neumann et al. 1999, "Compact metallic reflectance models"]
real Vis_Neumann(real NoV, real NoL)
{
	return 1 / (4 * max(NoL, NoV));
}

// [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
real Vis_Kelemen(real VoH)
{
	// constant to prevent NaN
	return rcp(4 * VoH * VoH + 1e-5);
}

// Tuned to match behavior of Vis_Smith
// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
real Vis_Schlick(real a2, real NoV, real NoL)
{
	real k = sqrt(a2) * 0.5;
	real Vis_SchlickV = NoV * (1 - k) + k;
	real Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / (Vis_SchlickV * Vis_SchlickL);
}

// Smith term for GGX
// [Smith 1967, "Geometrical shadowing of a random rough surface"]
real Vis_Smith(real a2, real NoV, real NoL)
{
	real Vis_SmithV = NoV + sqrt(NoV * (NoV - NoV * a2) + a2);
	real Vis_SmithL = NoL + sqrt(NoL * (NoL - NoL * a2) + a2);
	return rcp(Vis_SmithV * Vis_SmithL);
}

// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
real Vis_SmithJointApprox(real a2, real NoV, real NoL)
{
	real a = sqrt(a2);
	real Vis_SmithV = NoL * (NoV * (1 - a) + a);
	real Vis_SmithL = NoV * (NoL * (1 - a) + a);
	return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
}

real3 F_None(real3 SpecularColor)
{
	return SpecularColor;
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
real3 _F_Schlick(real3 SpecularColor, real VoH)
{
	real Fc = Pow5(1 - VoH);                   // 1 sub, 3 mul
												//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;

}

real3 F_Fresnel(real3 SpecularColor, real VoH)
{
	real3 SpecularColorSqrt = sqrt(clamp(real3(0, 0, 0), real3(0.99, 0.99, 0.99), SpecularColor));
	real3 n = (1 + SpecularColorSqrt) / (1 - SpecularColorSqrt);
	real3 g = sqrt(n * n + VoH * VoH - 1);
	return 0.5 * Square((g - VoH) / (g + VoH)) * (1 + Square(((g + VoH) * VoH - 1) / ((g - VoH) * VoH + 1)));
}

//---------------
// EnvBRDF
//---------------

//#ifndef PreIntegratedGF
//Texture2D		PreIntegratedGF;
//SamplerState	PreIntegratedGFSampler;
//#endif

half3 EnvBRDF( TEXTURE2D_SAMPLE_PARAM_DEF(PreIntegratedGF), half3 SpecularColor, half Roughness, half NoV)
{
	// Importance sampled preintegrated G * F
	real2 AB = SAMPLE_TEXTURE2D_LOD_DEF( PreIntegratedGF, real2(NoV, Roughness), 0).rg;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
	real3 GF = SpecularColor * AB.x + saturate(50.0 * SpecularColor.g) * AB.y;
	return GF;
}

half3 EnvBRDFApprox(half3 SpecularColor, half Roughness, half NoV)
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate(50.0 * SpecularColor.g);

	return SpecularColor * AB.x + AB.y;
}

half EnvBRDFApproxNonmetal(half Roughness, half NoV)
{
	// Same as EnvBRDFApprox( 0.04, Roughness, NoV )
	const half2 c0 = { -1, -0.0275 };
	const half2 c1 = { 1, 0.0425 };
	half2 r = Roughness * c0 + c1;
	return min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
}

real D_InvBlinn(real a2, real NoH)
{
	real A = 4;
	real Cos2h = NoH * NoH;
	real Sin2h = 1 - Cos2h;
	//return rcp( PI * (1 + A*m2) ) * ( 1 + A * ClampedPow( Sin2h, 1 / m2 - 1 ) );
	return rcp(PI * (1 + A * a2)) * (1 + A * exp(-Cos2h / a2));
}

real D_InvBeckmann(real a2, real NoH)
{
	real A = 4;
	real Cos2h = NoH * NoH;
	real Sin2h = 1 - Cos2h;
	real Sin4h = Sin2h * Sin2h;
	return rcp(PI * (1 + A * a2) * Sin4h) * (Sin4h + A * exp(-Cos2h / (a2 * Sin2h)));
}

real D_InvGGX(real a2, real NoH)
{
	real A = 4;
	real d = (NoH - a2 * NoH) * NoH + a2;
	return rcp(PI * (1 + A * a2)) * (1 + 4 * a2*a2 / (d*d));
}

real Vis_Cloth(real NoV, real NoL)
{
	return rcp(4 * (NoL + NoV - NoL * NoV));
}

#endif