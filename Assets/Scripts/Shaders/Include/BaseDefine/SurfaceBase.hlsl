#ifndef _SURFACE_BASE_HLSL_
#define _SURFACE_BASE_HLSL_

#include "ConstDefine.hlsl"
#include "CommonDefine.hlsl"
#include "SamplerUtils.hlsl"

struct Surface
{
	real3 baseColor;
	real  alpha;

	real3 diffColor;
	real3 specColor;
	real3 emissionColor;

	real  occlusion;
	real  specOcclusion;
	real  roughness;
	real  metallic;

	real3 specularLevel;	// specular level for dielectric reflectivity. default is zero. substance shader

	real3 normalVertexWorld;
	real3 normalWorld;
	real3 bitangent;
	real3 tangentWorld;
	real3 posWorld;
	real3 viewDir; // -eyeVec In Unity

	real anisotropyLv;
	
	real4 customData0;
	real4 customData1;

	real2 uv0;
	//real4 vertexSH;
};

void BuildSurfaceUV(inout Surface s, real2 baseUV)
{
	s.uv0 = baseUV;
}

void BuildSurfaceUV(inout Surface s, real2 baseUV, real heightInTex, real heightMax, real3 viewDir)
{
	s.uv0 = baseUV + ParallaxOffset1Step(heightInTex, heightMax, viewDir);
}

void BuildSurfaceDirtection(inout Surface s, real2 normalRG, real3 tangentWorld, real3 bitangent, real3 normalVertexWorld, real3 posWorld)
{
	s.normalVertexWorld = normalVertexWorld;

#ifdef USE_NORMAL_MAP
	real3 normalTS	= UnpackNormalRG(normalRG);
	s.normalWorld	= computeWSBaseNormalTS( normalTS, tangentWorld, bitangent, normalVertexWorld);

	//Create a local basis for BRDF work
	s.tangentWorld	= normalize( tangentWorld - s.normalWorld * dot(tangentWorld, s.normalWorld) );
	s.bitangent		= normalize( bitangent - s.normalWorld * dot(bitangent, s.normalWorld) - s.tangentWorld * dot(bitangent, s.tangentWorld) );
#else
	s.normalWorld	= normalVertexWorld;
	s.tangentWorld	= tangentWorld;
#endif

	if (dot(s.viewDir, s.normalWorld) < 0.0)
	{
		s.viewDir = reflect(s.viewDir, s.normalWorld);
	}

	s.posWorld = posWorld;
}

void BuildSurfaceAnisotropy(inout Surface s, real cosAnisotropyAngle, real sinAnisotropyAngle, real AnisotropyLv)
{
	real3 anisotropyCosSinLv = real3(cosAnisotropyAngle*2.0 - 1.0, sinAnisotropyAngle*2.0 - 1.0, AnisotropyLv);
	s.anisotropyLv = anisotropyCosSinLv.b;
	real3 tangentWorld	= s.tangentWorld;
	real3 bitangent		= s.bitangent;
	s.tangentWorld		= anisotropyCosSinLv.x * tangentWorld	- anisotropyCosSinLv.y * bitangent;
	s.bitangent			= anisotropyCosSinLv.x * bitangent		+ anisotropyCosSinLv.y * tangentWorld;
}

void BuildSurfaceAnisotropy(inout Surface s, real AnisotropyAngle, real AnisotropyLv)
{
	real radAngle = AnisotropyAngle*M_PI*2.0;
	real3 anisotropyCosSinLv = real3(cos(radAngle), sin(radAngle), AnisotropyLv);
	s.anisotropyLv = anisotropyCosSinLv.b;
	real3 tangentWorld	= s.tangentWorld;
	real3 bitangent		= s.bitangent;
	s.tangentWorld		= anisotropyCosSinLv.x * tangentWorld	- anisotropyCosSinLv.y * bitangent;
	s.bitangent			= anisotropyCosSinLv.x * bitangent		+ anisotropyCosSinLv.y * tangentWorld;
}

void SettingRoughness(real sampleRoughness, inout Surface s)
{
	s.roughness = max(0.02, sampleRoughness);
}

void SettingMetallic(real sampleMetallic, inout Surface s)
{
	s.metallic = sampleMetallic;
}

void SettingOcclusion(real sampleOccusion, inout Surface s)
{
	s.occlusion = sampleOccusion;// lerp(1.0, sampleOccusion, _OcclusionStrength);
	s.specOcclusion = specularOcclusionCorrection(s.occlusion, s.metallic, s.roughness);
}

void BuildSurfaceColor(inout Surface s, real3 baseColor, real alpha, real4 envCol, real roughness, real metallic, real occlusion, real specularLevel)
{
//#ifdef _ALPHATEST_ON
//	clip(s.alpha - _Cutoff);
//#endif

#if defined(UNITY_COLORSPACE_GAMMA) && !defined(USE_PRE_GAMMA2LINEAR)
	baseColor.xyz = GammaToLinearSpace(baseColor.xyz);
#endif

	s.baseColor = baseColor;
	s.alpha		= alpha;
	
	//s.vertexSH = envCol;

	s.specularLevel = specularLevel;
	
	SettingRoughness(roughness, s);
	SettingMetallic( metallic,	s);
	SettingOcclusion(occlusion, s);

	s.diffColor = GenerateDiffuseColor(s.baseColor, s.metallic);
	s.specColor = GenerateSpecularColor(MaxValue(s.specularLevel)+0.5, s.baseColor, s.metallic);

}


#endif