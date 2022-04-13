#ifndef _SAMPLER_UTILS_HLSL_
#define _SAMPLER_UTILS_HLSL_

#include "ConstDefine.hlsl"
#include "CommonDefine.hlsl"
#include "../BxDF/BxDFBaseFunction.hlsl"

#define DEFAULT_BASE_COLOR		real3(0.5,0.5,0.5)
#define DEFAULT_ROUGHNESS		0.3
#define DEFAULT_METALLIC		0.0
#define DEFAULT_OPACITY			1.0
#define DEFAULT_AO				1.0
#define DEFAULT_SPECULAR_LEVEL	10.5
#define DEFAULT_HEIGHT			0.0
#define DEFAULT_DISPLACEMENT	0.0

//----------Height Map

// Same as ParallaxOffset in Unity CG, except:
//  *) precision - half instead of float
real2 ParallaxOffset1Step(real h, real height, real3 v)
{
	h = h * height - height / 2.0;
	v.z += 0.42;
	return h * (v.xy / v.z);
}

//real2 Parallax(real2 uv, real3 viewDir)
//{
//	real h = SAMPLE_TEXTURE2D_DEF(_ParallaxMap, uv).r;
//	return ParallaxOffset1Step(h, _Parallax, viewDir);
//}

real3 UnpackNormalRG(real2 normalTexVal)
{
	real3 normalTS;
	normalTS.xy = (normalTexVal - 0.5) * 2.0;
	normalTS.z = sqrt(max(0, 1.0 - normalTS.x * normalTS.x - normalTS.y * normalTS.y));
	return normalize(normalTS);
}

real3 computeWSBaseNormalTS(real3 normalTS, real3 tangent, real3 bitangent, real3 normal)
{
	return normalize(normalTS.x * tangent +
		normalTS.y * bitangent +
		normalTS.z * normal);
}

//// Helper to compute the world space normal from tangent space base normal.
//real3 computeWSBaseNormal(real3 normalTexVal, real3 tangent, real3 bitangent, real3 normal)
//{
//	real3 normal_vec = UnpackNormal( normalTexVal );
//	return normalize(
//		normal_vec.x * tangent +
//		normal_vec.y * bitangent +
//		normal_vec.z * normal
//	);
//}

//----------Occlusion & _Roughness & Metallic  Start-----------------------------------
real DoLerpOneTo(real b, real t)
{
	real oneMinusT = 1 - t;
	return oneMinusT + b * t;
}

real specularOcclusionCorrection(real diffuseOcclusion, real metallic, real roughness)
{
	return lerp(diffuseOcclusion, 1.0, metallic * (1.0 - roughness) * (1.0 - roughness));
}

//void GetOcclusionRoughnessMetallic( TEXTURE2D_SAMPLE_PARAM_DEF( OccRoughMetalMap), inout Surface s)
//{
//	real3 texVar = SAMPLE_TEXTURE2D_DEF( OccRoughMetalMap, s.uv0).rgb;
//
//	SettingRoughness(texVar.g, s);
//	SettingMetallic(texVar.b, s);
//
////#ifdef UNITY_COLORSPACE_GAMMA
//	//texVar.r = LinearToGammaSpaceExact(texVar.r); // Substance use mixAO need to transfer to gamma space.
////#endif
//	SettingOcclusion(texVar.r, s);
//}

//real3 getCosSinAnisotropicLv( TEXTURE2D_SAMPLE_PARAM_DEF( _CosSinAnisotropicLvMap) , Surface s)
//{
//	real3 texVar = SAMPLE_TEXTURE2D_DEF( _CosSinAnisotropicLvMap, s.uv0).rgb;
//
//	texVar.r = texVar.r * 2.0 - 1.0;
//	texVar.g = sqrt(1.0 - texVar.r*texVar.r);
//	texVar.b  = texVar.b * _Anisotropy;
//
//	return texVar;
//}

//real3 getCosSinAnisotropicLv(real cosAnisotropyAngle, real lv)
//{
//	real3 texVar;

//	texVar.r = cosAnisotropyAngle * 2.0 - 1.0;
//	texVar.g = sqrt(1.0 - texVar.r*texVar.r);
//	texVar.b = lv;

//	return texVar;
//}

real3 GenerateDiffuseColor(real3 baseColor, real metallic)
{
	return baseColor * (1.0 - metallic);
}

real3 GenerateSpecularColor(real specularLevel, real3 baseColor, real metallic)
{
	return lerp(0.08 * specularLevel, baseColor, metallic);
}

//----------_EMISSION Start-----------------------------------
#if defined(USE_EMISSION_MAP)

real3 Emission( TEXTURE2D_SAMPLE_PARAM_DEF(emissionMap), real2 uv, real3 emissionColor)
{
#if defined(UNITY_COLORSPACE_GAMMA) && !defined(USE_PRE_GAMMA2LINEAR)
	return GammaToLinearSpace( SAMPLE_TEXTURE2D_DEF(emissionMap, uv).rgb )* emissionColor;
#else
	return SAMPLE_TEXTURE2D_DEF(emissionMap, uv).rgb * emissionColor;
#endif
}
#endif
//----------_EMISSION End-----------------------------------

//----------Scatter Start-----------------------------------
//----------Scatter End-----------------------------------

//void SetupPBROcclusionRoughnessMetallic( real roughness, real metallic, real occlusion  inout Surface s)
//{
//	SettingRoughness( roughness, s);
//	SettingMetallic(  metallic,  s);
//	SettingOcclusion( occlusion, s);
//
//	s.diffColor = GenerateDiffuseColor(s.baseColor, s.metallic);
//	s.specColor = GenerateSpecularColor(MaxValue(s.specularLevel) + 0.5f, s.baseColor, s.metallic);
//
//#if defined(USE_EMISSION_MAP)
//	s.emissionColor = Emission(TEXTURE_SAMPLE_ARGS_DEF(_EmissionMap), s.uv0);
//#endif
//}
#endif