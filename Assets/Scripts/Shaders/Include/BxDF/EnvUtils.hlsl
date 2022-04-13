#ifndef _ENV_UTILS_HLSL_
#define _ENV_UTILS_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
#include "../BaseDefine/SurfaceBase.hlsl"
#include "../BaseDefine/GBufferBase.hlsl"
#include "BxDFBaseFunction.hlsl"
#include "Anisotropic.hlsl"

#if USE_LIGHT_MAP
#define SETUP_LIGHTUV_OR_AMBIENT(i, normalWorld) BuildLightUV(i.lightmapUV)
#else
#define SETUP_LIGHTUV_OR_AMBIENT(i, normalWorld) BuildAmbient(normalWorld)
#endif

#ifdef USE_ENV_CUBE2D
TEXTURE2D_DEF(_EnvMap2D);
#endif

#if defined(USE_ENV_CUBE)
TEXTURECUBE_DEF(_EnvCubeMap);
#endif

#if defined(USE_ENV_PLANARREFLECTION)
TEXTURE2D_DEF(_PlanarReflectionTexture);
#endif

CBUFFER_START(UnityPerFrameEnv)

real		_MaxLod;

//: param auto environment_rotation
//real		environment_rotation;

//: param auto environment_exposure
real		_EnvironmentExposure;

//#if !defined(USE_ENV_UNITY_CUBE)
// SH lighting environment
real4		_SHAr;
real4		_SHAg;
real4		_SHAb;
real4		_SHBr;
real4		_SHBg;
real4		_SHBb;
real4		_SHC;
//#endif

//real4		_EnvCol;

CBUFFER_END

real3 UpAixsRotatorDir(real3 dir)
{
	real rot = 0;// environment_rotation * M_2PI;
	real crot = cos(rot);
	real srot = sqrt(1 - crot * crot);

	return real3(
		dir.x * crot - dir.z * srot,
		dir.y,
		dir.x * srot + dir.z * crot);
}

half3 SampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}

//#if defined(USE_ENV_CUBE2D)

//real3 envSampleLODTest(real3 reflectDir, real lod)
//{
//	real4 pos = 0.0;
//	pos.x = dot(reflectDir, real3(1.0, 0.0, 0.0));
//	pos.y = dot(reflectDir, real3(0.0, 1.0, 0.0));
//	pos.x = ((-texcoord.x) * 0.5) + 1.0);
//	pos.y = 1.0 - ((texcoord.y + 1.0) * 0.5));

//	//pos.x += environment_rotation;
//	pos.w = lod;

//	real4 col = SAMPLE_TEXTURE2D_LOD_DEF(_EnvMap2D, pos, lod);

//#if defined(UNITY_COLORSPACE_GAMMA) && !defined(USE_PRE_GAMMA2LINEAR)
//	return GammaToLinearSpace(col) * _EnvironmentExposure;
//#else
//	return col.rgb * _EnvironmentExposure;
//#endif
//}

//real3 envSampleLODInCube2D(real3 dir, real lod)
//{
//	// WORKAROUND: Intel GLSL compiler for HD5000 is bugged on OSX:
//	// https://bugs.chromium.org/p/chromium/issues/detail?id=308366
//	// It is necessary to replace atan(y, -x) by atan(y, -1.0 * x) to force
//	// the second parameter to be interpreted as a real
//	real2 pos = 0.0;
//	pos.xy = M_INV_PI * real2( atan2(dir.z , -dir.x), 2.0 * asin(dir.y));
//	pos.xy = 0.5 * pos + 0.5;
//	//pos.x += environment_rotation;

//	real4 col = SAMPLE_TEXTURE2D_LOD_DEF(_EnvMap2D, pos, lod);

//#if defined(UNITY_COLORSPACE_GAMMA) && !defined(USE_PRE_GAMMA2LINEAR)
//	return GammaToLinearSpace(col) * _EnvironmentExposure;
//#else
//	return col.rgb * _EnvironmentExposure;
//#endif
//}
//#endif

#if defined(USE_ENV_CUBE)
real3  envSampleLODInCube(real3 dir, real lod)
{
	real4 shDir = real4(dir, 1.0);

#if defined(UNITY_COLORSPACE_GAMMA) && !defined(USE_PRE_GAMMA2LINEAR)
	return GammaToLinearSpace( SAMPLE_TEXTURECUBE_LOD_DEF(_EnvCubeMap, shDir.xyz, lod).rgb ) * _EnvironmentExposure;
#else
	return SAMPLE_TEXTURECUBE_LOD_DEF(_EnvCubeMap, shDir.xyz, lod).rgb * _EnvironmentExposure;
#endif	
}
#endif

#if defined(USE_ENV_UNITY_CUBE)    
real3 envSampleLODInUnity(real3 dir, real lod)
{
	real4 skyData = 0.0;

#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
	skyData = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, dir, lod);

#if !defined(UNITY_USE_NATIVE_HDR)
	skyData.rgb = DecodeHDREnvironment(skyData, unity_SpecCube0_HDR);
//#else
//	skyData = skyData.rbg; // in unity urp define. this is real unbeliveable
#endif

#endif
	
	return skyData.xyz * _EnvironmentExposure;

}
#endif

real4 BuildLightUV(real2 lightuv)
{
	real4 ambientOrLightmapUV = 0;

	ambientOrLightmapUV.xy = lightuv * unity_LightmapST.xy + unity_LightmapST.zw;

	return ambientOrLightmapUV;
}

#if !defined(USE_ENV_UNITY_CUBE)
real3 envIrradianceInSH9(real3 dir)
{
	real4 shDir = real4(dir, 1.0);

	real3 sh9 = (real3)0.0;

	// Linear (L1) + constant (L0) polynomial terms
	sh9.r = dot(_SHAr, shDir);
	sh9.g = dot(_SHAg, shDir);
	sh9.b = dot(_SHAb, shDir);

	real3 x1, x2;
	real4 vB = shDir.xyzz * shDir.yzzx;

	x1.r = dot(_SHBr, vB);
	x1.g = dot(_SHBg, vB);
	x1.b = dot(_SHBb, vB);

	// Final (5th) quadratic (L2) polynomial
	real vC = shDir.x*shDir.x - shDir.y*shDir.y;
	x2 = _SHC.rgb * vC;

	// Quadratic polynomials
	sh9 += x1 + x2;

	return sh9 * _EnvironmentExposure;
}
#endif

real3 BuildSH9Vertex(real3 normalWorld)
{
	real3 shResult = 0.0;
#if  defined(USE_ENV_CUBE2D) || defined(USE_ENV_CUBE)  
	shResult.rgb += SHEvalLinearL2(normalWorld, _SHBr, _SHBg, _SHBb, _SHC);
#else
	shResult.rgb += SHEvalLinearL2(normalWorld, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);
#endif

	return shResult;
}

real4 BuildSH9Pixel(real3 normalWorld, real3 vertexSH)
{
	real4 shResult = 0.0;

#if  defined(USE_ENV_CUBE2D) || defined(USE_ENV_CUBE)
	shResult.rgb = SHEvalLinearL0L1(normalWorld, _SHAr, _SHAg, _SHAb) + vertexSH;
#else
	shResult.rgb = SHEvalLinearL0L1(normalWorld, unity_SHAr, unity_SHAg, unity_SHAb) + vertexSH;
#endif

	shResult.a = Luminance_(shResult.rgb);

	return shResult;
}

real4 BuildAmbient(real3 normalWorld)
{
	real4 shResult = 0.0;

#if  defined(USE_ENV_CUBE2D) || defined(USE_ENV_CUBE)  
	shResult.rgb = envIrradianceInSH9(normalWorld);
	shResult.a = Luminance_(shResult.rgb);
#else

	shResult.rgb = SampleSH(normalWorld);

	// Linear + constant polynomial terms
	shResult.rgb = SHEvalLinearL0L1(normalWorld, unity_SHAr, unity_SHAg, unity_SHAb);
	// Quadratic polynomials
	shResult.rgb += SHEvalLinearL2(normalWorld, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);

	shResult.a   = Luminance_(shResult.rgb);
#endif

	return shResult;
}

real3 EnvSampleLOD(real3 dir, real lod)
{
//#if defined(USE_ENV_CUBE2D)
//	return envSampleLODInMatcap(dir, lod);
#if defined(USE_ENV_CUBE)    
	return envSampleLODInCube(dir, lod);
#elif defined(USE_ENV_UNITY_CUBE)    
	return envSampleLODInUnity(dir, lod);
#else
	return 0;
#endif
}

real4 GetDiffuseGIColor(Surface s)
{
#if USE_LIGHT_MAP
	// Alpha is the gray of RGB, this can be pre-calculate.
	return UNITY_SAMPLE_TEX2D(unity_Lightmap, samplerunity_Lightmap, s.ambientOrLightmapUV);
#elif defined(USE_SH9_AVGCAL)
	BuildAmbientPixel(s.normalWorld ,s.ambientOrLightmapUV);
#else
	return BuildAmbient(s.normalWorld);
#endif
}


//real3 EnvBRDFApprox(real3 SpecularColor, real Roughness, real NoV)
//{
//	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
//	// Adaptation to fit our G term.
//	const real4 c0 = { -1, -0.0275, -0.572, 0.022 };
//	const real4 c1 = { 1, 0.0425, 1.04, -0.04 };
//
//	real4 r = Roughness * c0 + c1;
//	real a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
//	real2 AB = real2(-1.04, 1.04) * a004 + r.zw;
//
//	// Anything less than 2% is physically impossible and is instead considered to be shadowing
//	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
//	AB.y *= saturate(50.0 * SpecularColor.g);
//
//	return SpecularColor * AB.x + AB.y;
//}


real ComputeReflectionCaptureMipFromRoughness(real Roughness, real CubemapMaxMip)
{
	// Heuristic that maps roughness to mip level
	// This is done in a way such that a certain mip level will always have the same roughness, regardless of how many mips are in the texture
	// Using more mips in the cubemap just allows sharper reflections to be supported
	real LevelFrom1x1 = REFLECTION_CAPTURE_ROUGHEST_MIP - REFLECTION_CAPTURE_ROUGHNESS_MIP_SCALE * log2(Roughness);
	return CubemapMaxMip - 1 - LevelFrom1x1;
}

real3 ProjectCaptureVector(real3 viewDir, real3 normalWorld)
{
	return -reflect(viewDir, normalWorld);
}

// UE4 Mobile PBR
real3 GetImageBasedReflectionLighting(real roughness, real3 reflectDir, real4 diffuseGI)
{
	//#if HQ_REFLECTIONS
	//	half3 SpecularIBL = BlendReflectionCaptures(MaterialParameters, Roughness);
	//#else
	//real3 ProjectedCaptureVector = -reflect(s.viewDir, s.normalWorld);

	//real UsingSkyReflection = MobileReflectionParams.w > 0;
	real CubemapMaxMip = _MaxLod;//UsingSkyReflection ? MobileReflectionParams.w : ResolvedView.ReflectionCubemapMaxMip;

	// Compute fractional mip from roughness
	real AbsoluteSpecularMip = ComputeReflectionCaptureMipFromRoughness( roughness, CubemapMaxMip);
	// Fetch from cubemap and convert to linear HDR
	real3 SpecularIBL;
	real4 SpecularIBLSample = real4(EnvSampleLOD(reflectDir, AbsoluteSpecularMip), 1);  //ReflectionCubemap.SampleLevel(ReflectionCubemapSampler, ProjectedCaptureVector, AbsoluteSpecularMip);
	//if (UsingSkyReflection)
	//{
	//	SpecularIBL = SpecularIBLSample.rgb;
	//	// Apply sky colour if the reflection map is the sky.
	//	SpecularIBL *= ResolvedView.SkyLightColor.rgb;
	//}
	//else
	//{
	SpecularIBL = SpecularIBLSample.rgb;// RGBMDecode(SpecularIBLSample, 16.0);
	//SpecularIBL = SpecularIBL * SpecularIBL;
//#if LQ_TEXTURE_LIGHTMAP || CACHED_POINT_INDIRECT_LIGHTING
//		// divide by average brightness for lightmap use cases only.
//		SpecularIBL *= MobileReflectionParams.x;
//#endif
	//}

//#endif
	//real MixingAlpha = smoothstep(0, 1, saturate((roughness - 0) / (1 - 0)));
	real MixingAlpha = smoothstep(0, 1, saturate(roughness) );

	real3 AverageBrightness = max(dot(diffuseGI.rgb, real3(0.333, 0.333, 0.333)), 0.001);

	real3 MixingWeight = diffuseGI.w / AverageBrightness;

	SpecularIBL.rgb *= lerp(1.0, MixingWeight, MixingAlpha);

	return SpecularIBL;
}

real3 GetImageBasedReflectionLightingAnisotropy(Surface s, real4 diffuseGI)
{
	real3 grainNormal = GetAnisotropicModifiedNormal(s.tangentWorld, s.normalWorld, s.viewDir, s.anisotropyLv);
	real3 reflectDir = ProjectCaptureVector(s.viewDir, grainNormal);
	return GetImageBasedReflectionLighting(s.roughness, reflectDir, diffuseGI);
}

real3 GetReflectionLighting(Surface s, real4 diffuseGI)
{
	#if defined(USE_ANISOTROPIC)
		return GetImageBasedReflectionLightingAnisotropy(s, diffuseGI);
	#else
		real3 reflectDir = ProjectCaptureVector(s.viewDir, s.normalWorld);
		return GetImageBasedReflectionLighting(s.roughness, reflectDir, diffuseGI);
	#endif
}

real3 GetInDeferredReflectionLighting(Surface s, real4 diffuseGI, int MaterialID)
{
	if (MaterialID = MaterialID_Anisotropic)
    {
		return GetImageBasedReflectionLightingAnisotropy(s, diffuseGI);
    }
	else
    {
		real3 reflectDir = ProjectCaptureVector(s.viewDir, s.normalWorld);
		return GetImageBasedReflectionLighting(s.roughness, reflectDir, diffuseGI);
    }
}

#if defined(USE_ENV_PLANARREFLECTION)
real3 PlanarReflections(half3 normalWS, half2 screenUV, half roughness)
{
	//real3 reflection = 0;
	//real2 refOffset = 0;

	// get the perspective projection
	//float2 p11_22 = float2(unity_CameraInvProjection._11, unity_CameraInvProjection._22) * 10;
	// conver the uvs into view space by "undoing" projection
	//float3 viewDir = -(float3((screenUV * 2 - 1) / p11_22, -1));

	//real3 viewNormal = mul(normalWS, (float3x3)UNITY_MATRIX_V).xyz;
	//real3 reflectVector = reflect(-viewDir, viewNormal);

	real2 reflectionUV = screenUV + normalWS.zx * real2(0.002, 0.015);

	reflection = SAMPLE_TEXTURE2D_LOD(_PlanarReflectionTexture, sampler_PlanarReflectionTexture, reflectionUV, 6 * roughness).rgb;//planar reflection

	//do backup
	//return reflectVector.yyy;
	return reflection;
}
#endif

#endif