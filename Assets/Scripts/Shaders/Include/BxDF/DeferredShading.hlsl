#ifndef _DEFERRED_SHADING_HLSL_
#define _DEFERRED_SHADING_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
#include "../BaseDefine/LightingBase.hlsl"
#include "../BaseDefine/SurfaceBase.hlsl"
#include "../BaseDefine/GBufferBase.hlsl"
#include "BxDFContext.hlsl"
#include "BxDFBaseFunction.hlsl"
#include "UEBasePhysicBxDF.hlsl"
#include "UEShadingBase.hlsl"
#include "Anisotropic.hlsl"

TEXTURE2D_DEF(_LUTTex);

real3 CalScatterColor(real halfNoL, real falloff, real curvex)
{
	return SAMPLE_TEXTURE2D_DEF( _LUTTex, real2(halfNoL * falloff, curvex) ).rgb;
}

float3 CalLUTLightFalloff( Light l, real NoL, real curvex)
{
	real halfNoL = NoL > 0.0f ? NoL * 0.5 + 0.5 : 0.0f;
	return l.color * CalScatterColor( halfNoL, l.attenuation, curvex);
}

float3 CalLUTLightFalloffSimple( Light l, real NoL)
{
	real curvex = 0.5;

	real halfNoL = NoL > 0.0f ? NoL * 0.5 + 0.5 : 0.0f;

	return l.color * CalScatterColor( halfNoL, l.attenuation, curvex);
}

real3 CalFalloffColor(BxDFContext c, real NoL, Light l)
{
	return l.color * l.attenuation * NoL;
}

real3 CalLUTFalloffColor(BxDFContext c, real NoL, Light l, real curvex = 0.5)
{
	return l.color * CalLUTLightFalloff(l, NoL, curvex);
}

real3 CalDiffuse(Surface s, BxDFContext c, real NoL)
{
#if defined(USE_GOTANDA_DIFFUSE)
	return Diffuse_Gotanda(s.diffColor, s.roughness, c.NoV, NoL, c.VoH);
#elif  defined(USE_O_N_DIFFUSE)
	return Diffuse_OrenNayar(s.diffColor, s.roughness, c.NoV, NoL, c.VoH);
#elif defined(USE_DISNEY_DIFFUSE)
	return Diffuse_Burley(s.diffColor, s.roughness, c.NoV, NoL, c.VoH);
#else // defined(USE_LAMBERT_DIFFUSE)
	return  Diffuse_Lambert(s.diffColor);
#endif
}

real3 SchlickBackMannSpec(Surface s, real roughness, real3 specColor, BxDFContext c, real NoL, Light l)
{
	real a2 = Pow4(roughness);
	//real Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

	real3 spec;

	// Generalized microfacet specular
	real D = _D_GGX(a2, c.NoH);// *Energy;
	//real D = D_Blinn(a2, c.NoH);// *Energy;
	

	real Vis = Vis_SmithJointApprox(a2, c.NoV, NoL);
	//real Vis = Vis_Kelemen(c.VoH);
	//real Vis = Vis_Smith(a2, c.NoV, NoL);

	real3 F = _F_Schlick(specColor, c.VoH);

	spec = D * Vis* F;

	return spec;
}

real3 SchlickBackMannSpecAnisotropic(Surface s, real roughness, real3 specColor, BxDFContext c, real NoL, Light l)
{
	real a2 = Pow4(roughness);
	//real Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

	real3 spec;
	
	real roughnessT = 0.0;
	real roughnessB = 0.0;

	//Normal shift
	real shiftAmount = dot(s.normalWorld, s.viewDir);
	s.normalWorld = shiftAmount < 0.0f ? normalize(s.normalWorld + s.viewDir * (-shiftAmount + 1e-5f)) : s.normalWorld;

	_ConvertAnisotropyToRoughness(s.roughness, s.anisotropyLv, roughnessT, roughnessB);

	real3 H	 = normalize(s.viewDir + l.direction);

	real VoT = dot(s.viewDir, s.tangentWorld);
	real VoB = dot(s.viewDir, s.bitangent);
	real ToL = dot(s.tangentWorld, l.direction);
	real BoL = dot(s.bitangent, l.direction);

	real ToH = dot(s.tangentWorld,  H);
	real BoH = dot(s.bitangent,		H);

	real D = D_GGXaniso( ToH, BoH, c.NoH, roughnessT, roughnessB);

	real Vis = Vis_SmithJointAniso( VoT, VoB, c.NoV, ToL, BoL, NoL, roughnessT, roughnessB);
	//real Vis = Vis_SmithJointAniso( VoT, VoB, c.NoV, ToL, BoL, c.NoL, roughnessT, roughnessB);

	real3 F = F_Schlick(specColor, c.VoH);

	spec = D * Vis  * F;
	
	return spec;
}

real3 BlinnPhone(Surface s, real roughness, real3 specColor, BxDFContext c, real NoL, Light l)
{
	real a2 = Pow4(roughness);
	real3 spec;

	real D  = D_Blinn(a2, c.NoH);
	real Vis = Vis_Implicit();
	real3 F = _F_Schlick(specColor, c.VoH);
	spec = D * Vis * F;

	return spec;
}

real3 BlinnKelemenPhone(Surface s, real roughness, real3 specColor, BxDFContext c, real NoL, Light l)
{
	real a2 = Pow4(roughness);
	real3 spec;

	real D = D_Blinn(a2, c.NoH);
	real Vis = Vis_Kelemen(c.VoH);
	real3 F = _F_Schlick(specColor, c.VoH);
	spec = D * Vis * F;

	return spec;
}


FDirectLighting DefaultLitBxDF(Surface s, Light l)
{
	real3 N = s.normalWorld;
	real3 V = s.viewDir;
	real NoL = max(0, dot(N,l.direction));
	
	BxDFContext c;
	InitBxDFContext(c, N, V, l.direction);
	//SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
	//context.NoV = saturate(abs(context.NoV) + 1e-5);

	real3 falloffColor = CalFalloffColor(c, NoL, l);

	FDirectLighting Lighting;

	Lighting.Diffuse = falloffColor * s.occlusion * CalDiffuse(s, c, NoL);
	
	real3 specTerm = EnvBRDFApprox(s.specColor, s.roughness, c.NoV);
	
	Lighting.Specular = falloffColor * SchlickBackMannSpec(s, s.roughness, specTerm, c, NoL, l) * s.specOcclusion;
	
	Lighting.Transmission = 0;
	
	return Lighting;
}

FDirectLighting AnisotropicLitBxDF(Surface s, Light l)
{
	real3 N = s.normalWorld;
	real3 V = s.viewDir;
	real NoL = max(0, dot(N,l.direction));
	
	BxDFContext c;
	InitBxDFContext(c, N, V, l.direction);
	//SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
	//context.NoV = saturate(abs(context.NoV) + 1e-5);

	real3 falloffColor = CalFalloffColor(c, NoL, l);

	FDirectLighting Lighting;

	Lighting.Diffuse = falloffColor * s.occlusion * CalDiffuse(s, c, NoL);
	
	real3 specTerm = EnvBRDFApprox(s.specColor, s.roughness, c.NoV);
	
	Lighting.Specular = falloffColor * SchlickBackMannSpecAnisotropic(s, s.roughness, specTerm, c, NoL, l) * s.specOcclusion;
	
	//Lighting.Specular = SchlickBackMannSpecAnisotropic(s, s.roughness, specTerm, c, NoL, l);
	//Lighting.Specular = s.bitangent;
	
	Lighting.Transmission = 0;
	
	return Lighting;
}

FDirectLighting ClearCoatBxDF(Surface s, Light l, real3 Nspec, real clearCoatRoughness, real clearCoat)
{
	real3 N = s.normalWorld;
	real3 V = s.viewDir;
	real NoL = max(0, dot(N,l.direction));
	
	real ClearCoatRoughness = max(clearCoatRoughness, 0.02f);
	//real Film = 1 * _ClearCoat;
	const real MetalSpec = 0.9;

#if 1
	BxDFContext c;

	real NoLSpec = NoL;

	//if (CLEAR_COAT_BOTTOM_NORMAL)
	//{
	//	Nspec = GBuffer.WorldNormal;
	//}

	InitBxDFContext(c, Nspec, V, l.direction);
	//SphereMaxNoH(Context, AreaLight.SphereSinAlpha, CLEAR_COAT_BOTTOM_NORMAL == 0);
	c.NoV = saturate(abs(c.NoV) + 1e-5);
	//Context.VoH = AreaLight.bIsRect ? Context.NoV : Context.VoH;

	//if (CLEAR_COAT_BOTTOM_NORMAL)
	//{
	//	NoLSpec = saturate(Context.NoL + 1e-5);
	//}

	// F_Schlick
	real F0 = 0.04;
	real Fc = Pow5(1 - c.VoH);
	real F = Fc + (1 - Fc) * F0;
	F *= clearCoat;

	real3 falloffColor = CalFalloffColor(c, NoL, l);

	FDirectLighting Lighting;

	//if (AreaLight.bIsRect)
	//{
	//	Lighting.Specular = ClearCoat * RectGGXApproxLTC(ClearCoatRoughness, F0, Nspec, V, AreaLight.Rect, AreaLight.Texture);
	//}
	//else
	//{
		real a2 = Pow4(ClearCoatRoughness);
		//real Energy = EnergyNormalization(a2, Context.VoH, AreaLight);

		// Generalized microfacet specular
		real D = _D_GGX(a2, c.NoH);// *Energy;
		real Vis = Vis_SmithJointApprox(a2, c.NoV, NoLSpec);

		Lighting.Specular = falloffColor * NoLSpec * D * Vis * F;
	//}

	//if (CLEAR_COAT_BOTTOM_NORMAL)
	//{
	//	InitBxDFContext(Context, N, V, L);
	//	SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
	//	Context.NoV = saturate(abs(Context.NoV) + 1e-5);
	//}

	real LayerAttenuation = (1 - F);

	falloffColor *= LayerAttenuation;

	Lighting.Diffuse = falloffColor * CalDiffuse(s, c, NoL) * s.occlusion;

	real3 specTerm = EnvBRDFApprox(s.specColor, s.roughness, c.NoV);
	//if (AreaLight.bIsRect)
	//{
	//	Lighting.Specular += LayerAttenuation * RectGGXApproxLTC(GBuffer.Roughness, GBuffer.SpecularColor, N, V, AreaLight.Rect, AreaLight.Texture);
	//}
	//else
	//{
		Lighting.Specular += falloffColor * SchlickBackMannSpec( s, s.roughness, specTerm, c, NoL, l) * s.specOcclusion;
	//}

	Lighting.Transmission = 0;
	return Lighting;
#else
	real3 H = normalize(V + L);
	real NoL = saturate(dot(N, L));
	real NoV = saturate(abs(dot(N, V)) + 1e-5);
	real NoH = saturate(dot(N, H));
	real VoH = saturate(dot(V, H));

	// Hard coded IOR of 1.5

	// Generalized microfacet specular
	real D = _D_GGX(ClearCoatRoughness, NoH) * LobeEnergy[0];
	real Vis = Vis_SmithJointApprox(a2, Context.NoV, NoL);

	// F_Schlick
	real F0 = 0.04;
	real Fc = Pow5(1 - VoH);
	real F = Fc + (1 - Fc) * F0;

	real Fr1 = D * Vis * F;

	// Refract rays
	//real3 L2 = refract( -L, -H, 1 / 1.5 );
	//real3 V2 = refract( -V, -H, 1 / 1.5 );

	// LoH == VoH
	//real RefractBlend = sqrt( 4 * VoH*VoH + 5 ) / 3 + 2.0 / 3 * VoH;
	//real3 L2 = RefractBlend * H - L / 1.5;
	//real3 V2 = RefractBlend * H - V / 1.5;
	//real NoL2 = saturate( dot(N, L2) );
	//real NoV2 = saturate( dot(N, V2) );

	// Approximation
	real RefractBlend = (0.22 * VoH + 0.7) * VoH + 0.745;	// 2 mad
	// Dot products distribute. No need for L2 and V2.
	real RefractNoH = RefractBlend * NoH;					// 1 mul
	real NoL2 = saturate(RefractNoH - (1 / 1.5) * NoL);	// 1 mad
	real NoV2 = saturate(RefractNoH - (1 / 1.5) * NoV);	// 1 mad
	// Should refract H too but unimportant

	NoL2 = max(0.001, NoL2);
	NoV2 = max(0.001, NoV2);

	real  AbsorptionDist = rcp(NoV2) + rcp(NoL2);
	real3 Absorption = pow(AbsorptionColor, 0.5 * AbsorptionDist);

	// Approximation
	//real  AbsorptionDist = ( NoV2 + NoL2 ) / ( NoV2 * NoL2 );
	//real3 Absorption = AbsorptionColor * ( AbsorptionColor * (AbsorptionDist * 0.5 - 1) + (2 - 0.5 * AbsorptionDist) );
	//real3 Absorption = AbsorptionColor + AbsorptionColor * (AbsorptionColor - 1) * (AbsorptionDist * 0.5 - 1);	// use for shared version

	//real F21 = Fresnel( 1 / 1.5, saturate( dot(V2, H) ) );
	//real TotalInternalReflection = 1 - F21 * G_Schlick( Roughness, NoV2, NoL2 );
	//real3 LayerAttenuation = ( (1 - F12) * TotalInternalReflection ) * Absorption;

	// Approximation
	real3 LayerAttenuation = (1 - F) * Absorption;

	// Approximation for IOR == 1.5
	//SpecularColor = ChangeBaseMedium( SpecularColor, 1.5 );
	//SpecularColor = saturate( ( 0.55 * SpecularColor + (0.45 * 1.08) ) * SpecularColor - (0.45 * 0.08) );
	// Treat SpecularColor as relative to IOR. Artist compensates.

	// Generalized microfacet specular
	real D2 = _D_GGX(Pow4(Roughness), NoH) * LobeEnergy[2];
	real Vis2 = Vis_SmithJointApprox(Pow4(Roughness), NoV2, NoL2);
	real3 F2 = F_Schlick(GBuffer.SpecularColor, VoH);

	real3 Fr2 = Diffuse_Lambert(GBuffer.DiffuseColor) * LobeEnergy[2] + (D2 * Vis2) * F2;

	return Fr1 + Fr2 * LayerAttenuation;
#endif
}

FDirectLighting ClothBxDF(Surface s, Light l, real3 fuzzColor, real cloth)
{
	real3 N = s.normalWorld;
	real3 V = s.viewDir;
	real NoL = max(0, dot(N,l.direction));
	
	//real3 FuzzColor = saturate(GBuffer.CustomData.rgb);
	//real  Cloth = saturate(GBuffer.CustomData.a);

	BxDFContext c;
	InitBxDFContext(c, N, V, l.direction);
	//SphereMaxNoH(Context, AreaLight.SphereSinAlpha, true);
	c.NoV = saturate(abs(c.NoV) + 1e-5);

	real3 falloffColor = CalFalloffColor(c, NoL, l);

	real3 specTerm = EnvBRDFApprox(s.specColor, s.roughness, c.NoV);
	
	//if (AreaLight.bIsRect)
	//	Spec1 = RectGGXApproxLTC(GBuffer.Roughness, GBuffer.SpecularColor, N, V, AreaLight.Rect, AreaLight.Texture);
	//else
	
	real a2 = Pow4(s.roughness);
	real D = _D_GGX(a2, c.NoH);// *Energy;
	real Vis = Vis_SmithJointApprox(a2, c.NoV, NoL);
	real3 F = _F_Schlick(specTerm, c.VoH);
	
	real3 Spec1 = D * Vis * F;

	// Cloth - Asperity Scattering - Inverse Beckmann Layer
	real D2 = D_InvGGX(a2, c.NoH);
	real Vis2 = Vis_Cloth(c.NoV, NoL);
	real3 F2 = F_Schlick(fuzzColor, c.VoH);
	real3 Spec2 = (D2 * Vis2) * F2;

	FDirectLighting Lighting;
	Lighting.Diffuse = falloffColor * s.occlusion * CalDiffuse(s, c, NoL);
	Lighting.Specular = falloffColor * lerp(Spec1, Spec2, cloth) * s.specOcclusion;
	Lighting.Transmission = 0;
	return Lighting;
}

void LitDecodeGBufferToSurface(inout Surface s, real3 baseColor, real4 GBuffer1, real4 GBuffer2, real3 posWorld)
{
    s.baseColor = baseColor;
    s.alpha = 1.0f;
    s.metallic = GBuffer2.x;
    s.roughness = GBuffer2.y;
    s.occlusion = GBuffer2.z;
	s.specOcclusion = specularOcclusionCorrection(s.occlusion, s.metallic, s.roughness);
    
    s.diffColor = GenerateDiffuseColor(s.baseColor, s.metallic);
	s.specColor = GenerateSpecularColor(MaxValue(s.specularLevel)+0.5, s.baseColor, s.metallic);
    
    s.normalWorld.xyz = normalize(GBuffer1.xyz * 2.0 - 1.0);
    
    s.viewDir = normalize(_WorldSpaceCameraPos - posWorld.xyz);
    if (dot(s.viewDir, s.normalWorld) < 0.0)
	{
		s.viewDir = reflect(s.viewDir, s.normalWorld);
	}
    
    s.posWorld = posWorld; 
}

void AnisotropicDecodeGBufferToSurface(inout Surface s, real3 baseColor, real4 GBuffer1, real4 GBuffer2, real4 GBuffer3, real3 posWorld)
{
    s.baseColor = baseColor;
    s.alpha = 1.0f;
    s.metallic = GBuffer2.x;
    s.roughness = GBuffer2.y;
    s.occlusion = GBuffer2.z;
    s.specOcclusion = specularOcclusionCorrection(s.occlusion, s.metallic, s.roughness);
    
    s.diffColor = GenerateDiffuseColor(s.baseColor, s.metallic);
	s.specColor = GenerateSpecularColor(MaxValue(s.specularLevel)+0.5, s.baseColor, s.metallic);
    
    s.normalWorld.xyz = normalize(GBuffer1.xyz * 2.0 - 1.0);
    
    s.tangentWorld.xyz = normalize( GBuffer3.xyz * 2.0 - 1.0 ) ;
    s.anisotropyLv = GBuffer3.w;
	
	s.bitangent = normalize(cross(s.normalWorld, s.tangentWorld));
	
    
    s.viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
    if (dot(s.viewDir, s.normalWorld) < 0.0)
	{
		s.viewDir = reflect(s.viewDir, s.normalWorld);
	}
    
    s.posWorld = posWorld; 
}

void ClearCoatDecodeGBufferToSurface(inout Surface s, real3 baseColor, real4 GBuffer1, real4 GBuffer2, real4 GBuffer3, real3 posWorld)
{
	LitDecodeGBufferToSurface(s, baseColor, GBuffer1, GBuffer2, posWorld);
	s.customData0.xy = real2(GBuffer1.w, GBuffer2.w);
	s.customData1 = GBuffer3;
}

void ClothDecodeGBufferToSurface(inout Surface s, real3 baseColor, real4 GBuffer1, real4 GBuffer2, real4 GBuffer3, real3 posWorld)
{
	LitDecodeGBufferToSurface(s, baseColor, GBuffer1, GBuffer2, posWorld);
	s.customData0 = GBuffer3;
}

void DecodeGBufferToSurface(inout  Surface s, int MaterialID, real3 baseColor, real4 gbuffer1, real4 gbuffer2, real4 gbuffer3, real3 posWorld)
{
	if (MaterialID == MaterialID_Lit)
    {
		LitDecodeGBufferToSurface(s, baseColor, gbuffer1, gbuffer2, posWorld.xyz);
		s.emissionColor.xyz = gbuffer3.xyz; // because only can supported 4 MRT emissionColor only can be use in default Lit.
    }
	else if (MaterialID == MaterialID_Anisotropic)
    {
		AnisotropicDecodeGBufferToSurface(s, baseColor, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
	}
	else if (MaterialID == MaterialID_Clearcoat)
    {
    }
    else if (MaterialID == MaterialID_Cloth)
    {
        ClothDecodeGBufferToSurface(s, baseColor, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
    }
    else if (MaterialID == MaterialID_SubSurfaceScattering)
    {
        
    }
}

FDirectLighting Lit(Light l, Surface s, int MaterialID)
{
	FDirectLighting lighting = (FDirectLighting)0;
	if (MaterialID == MaterialID_Lit)
    {
		lighting = DefaultLitBxDF(s,l);
	}
    else if (MaterialID == MaterialID_Anisotropic)
    {
		lighting = AnisotropicLitBxDF(s,l);
		//lighting = DefaultLitBxDF(s,l);
	}
    else if (MaterialID == MaterialID_Clearcoat)
    {
        lighting = ClearCoatBxDF(s,l, s.customData1.xyz, s.customData0.x, s.customData0.y);
    }
    else if (MaterialID == MaterialID_Cloth)
    {
		lighting = ClothBxDF(s, l, s.customData0.xyz, s.customData0.w);
    }
    else if (MaterialID == MaterialID_SubSurfaceScattering)
    {
        lighting = DefaultLitBxDF(s,l);
    }
	
	return lighting;
}


FDirectLighting SimpleLit(Light l, Surface s)
{
	FDirectLighting lighting = (FDirectLighting)0;
	
	real3 N = s.normalWorld;
	real3 V = s.viewDir;
	real NoL = max(0, dot(N,l.direction));
	
	BxDFContext c;
	InitBxDFContext(c, N, V, l.direction);
	
	real3 falloffColor = CalFalloffColor(c, NoL, l);
	
	lighting.Diffuse = falloffColor * s.occlusion * s.diffColor;
	
	real3 specTerm = EnvBRDFApprox(s.specColor, s.roughness, c.NoV);
	
	lighting.Specular = falloffColor * c.VoH * specTerm * s.specOcclusion;
	
	return lighting;
}
#endif