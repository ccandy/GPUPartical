#ifndef _ANISOTROPIC_HLSL_
#define _ANISOTROPIC_HLSL_
#include "BxDFBaseFunction.hlsl"

// Render Monkey Ruby Hair
real HairSingleSpecularTerm(real3 T, real3 H, real exponent)
{
	real dotTH = dot(T, H);
	real sinTH = sqrt(1.0 - dotTH * dotTH);
	return pow(sinTH, exponent);
}

// Render Monkey Ruby Hair
real3 _ShiftTangent(real3 T, real3 N, real shiftAmount)
{
	return normalize(T + shiftAmount * N);
}

// Anisotropic GGX
// From Unity HDRenderPipeline
real D_GGXAnisotropic(real TdotH, real BdotH, real NdotH, real roughnessT, real roughnessB)
{
	real f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
	return 1.0 / (roughnessT * roughnessB * f * f);
}

// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
real D_GGXaniso(real TdotH, real BdotH, real NdotH, real roughnessT, real roughnessB)
{
// The two formulations are mathematically equivalent
#if 1
	float a2 = roughnessT * roughnessB;
	float3 V = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
	float S = dot(V, V);

	return (1.0f / M_PI) * a2 * Square(a2 / S);
#else
	float d = TdotH*TdotH / (roughnessT*roughnessT) + BdotH*BdotH / (roughnessB*roughnessB) + NdotH*NdotH;
	return 1.0f / ( PI * roughnessT*roughnessB * d*d );
#endif
}

// Smith Joint GGX Anisotropic Visibility
// Taken from https://cedec.cesa.or.jp/2015/session/ENG/14698.html
real V_SmithJointGGXAnisotropic(real TdotV, real BdotV, real NdotV, real TdotL, real BdotL, real NdotL, real roughnessT, real roughnessB)
{
	real aT = roughnessT;
	real aT2 = aT * aT;
	real aB = roughnessB;
	real aB2 = aB * aB;

	real lambdaV = NdotL * sqrt(aT2 * TdotV * TdotV + aB2 * BdotV * BdotV + NdotV * NdotV);
	real lambdaL = NdotV * sqrt(aT2 * TdotL * TdotL + aB2 * BdotL * BdotL + NdotL * NdotL);

	return 0.5 / (lambdaV + lambdaL);
}

// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointAniso( real TdotV, real BdotV, real NdotV, real TdotL, real BdotL, real NdotL, real roughnessT, real roughnessB)
{
	real Vis_SmithV = NdotL * length(real3(roughnessT * TdotV, roughnessB * BdotV, NdotV));
	real Vis_SmithL = NdotV * length(real3(roughnessT * TdotL, roughnessB * BdotL, NdotL));
	return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
}

// Convert Anistropy to roughness
void _ConvertAnisotropyToRoughness(real roughness, real anisotropy, out real roughnessT, out real roughnessB)
{
	// (0 <= anisotropy <= 1), therefore (0 <= anisoAspect <= 1)
	// The 0.9 factor limits the aspect ratio to 10:1.
	real anisoAspect = sqrt(1.0 - 0.9 * anisotropy);
	roughnessT = roughness / anisoAspect; // Distort along tangent (rougher)
	roughnessB = roughness * anisoAspect; // Straighten along bitangent (smoother)
}

// Ref: Donald Revie - Implementing Fur Using Deferred Shading (GPU Pro 2)
// The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to the normal.
// The returned normal is NOT normalized.
real3 ComputeGrainNormal(real3 grainDir, real3 V)
{
	real3 B = cross(V, grainDir);
	return cross(B, grainDir);
}


#endif