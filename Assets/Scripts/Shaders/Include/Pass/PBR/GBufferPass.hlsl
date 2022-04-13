#ifndef _GBUFFER_PASS_HLSL_
#define	_GBUFFER_PASS_HLSL_

#include "GBufferBuffer.hlsl"
#include "../../BaseDefine/LightingBase.hlsl"
#include "../../BaseDefine/ShadowBase.hlsl"
#include "../../BaseDefine/VertexBase.hlsl"
#include "../../BaseDefine/SurfaceBase.hlsl"
#include "../../BxDF/EnvUtils.hlsl"

struct Attributes
{
	float4 vertex			: POSITION;
	float4 color			: COLOR;
	float2 uv0				: TEXCOORD0;
	float3 normal			: NORMAL;
	float4 tangent			: TANGENT;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	real4 positionCS	: SV_POSITION;
	real2 uv			: TEXCOORD0;
	real3 tangentWorld	: TEXCOORD2;
	real3 bitangent		: TEXCOORD3;
	real3 normalWorld	: TEXCOORD4;
	real3 posWorld		: TEXCOORD5;
	real3 color			: TEXCOORD6;

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
	
struct GBufferOutput
{
	real4 AlbedoMaterialMask : SV_Target0;
    real4 GBuffer1 : SV_Target1; // NormalRGB			
    real4 GBuffer2 : SV_Target2; // MetalRoughnessAO  
    real4 GBuffer3 : SV_Target3; // Emission | Tangent(RGB) AnisotropyLv(A)
};

Varyings GBufferLitVert(Attributes v)
{
	Varyings o = (Varyings)0;

	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	VertexData vData = BuildVertexData(v.vertex, v.normal, v.tangent);

	o.uv				= TRANSFORM_TEX(v.uv0, _BaseMap);
	o.tangentWorld.xyz	= vData.tangentWorld.xyz;
	o.bitangent.xyz		= vData.bitangent.xyz;
	o.normalWorld.xyz	= vData.normalWorld.xyz;
	o.posWorld.xyz		= vData.posWorld.xyz;
	o.positionCS		= vData.posMVP;
	o.color				= v.color.xyz;

	return o;
}

GBufferOutput GBufferLitFrag(Varyings i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	Surface s = (Surface)0;
		
	s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
		
#ifdef USE_HEIGHT_MAP
	float h = SAMPLE_TEXTURE2D_DEF(_HeightMap, i.uv);
	BuildSurfaceUV(s, i.uv, h, _Height, s.viewDir);
#else
	BuildSurfaceUV(s, i.uv);
#endif
	
	real3 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0).xyz * i.color.xyz * _BaseColor.xyz;

	real3 normalRG = SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0).xyz;

	real4 MetalRoughAO = SAMPLE_TEXTURE2D_DEF(_MetalRoughAOTex, s.uv0);
		
	real3 normalWorld = i.normalWorld;
	real3 tangentWorld = i.tangentWorld;
		
	BuildSurfaceDirtection( s, normalRG.xy, tangentWorld, i.bitangent, normalWorld, i.posWorld);

	MetalRoughAO.x = MetalRoughAO.x * _Metallic;
	MetalRoughAO.y = max(0.02, MetalRoughAO.y * _Roughness);
	MetalRoughAO.z = MetalRoughAO.z * _OcclusionStrength;

	GBufferOutput output = (GBufferOutput)0;
				
	output.AlbedoMaterialMask = real4(baseColor, EncodeMaterialID(MaterialID_Lit));
	output.GBuffer1			  = real4(s.normalWorld.xyz*0.5 + 0.5, 1);
	output.GBuffer2			  = MetalRoughAO;
	output.GBuffer3			  = real4(SAMPLE_TEXTURE2D_DEF(_EmissionTex, s.uv0));
		
	return output;
}

GBufferOutput GBufferLitAnisotropyFrag(Varyings i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	Surface s = (Surface)0;
		
	s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
		
#ifdef USE_HEIGHT_MAP
	float h = SAMPLE_TEXTURE2D_DEF(_HeightMap, i.uv);
	BuildSurfaceUV(s, i.uv, h, _Height, s.viewDir);
#else
	BuildSurfaceUV(s, i.uv);
#endif
	
	real3 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0).xyz * i.color.xyz * _BaseColor.xyz;

	real4 normalRGAnsiCosSinBA = SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0);

	real4 MetalRoughAOAnisotropyLv = SAMPLE_TEXTURE2D_DEF(_MetalRoughAOTex, s.uv0);
		
	real3 normalWorld = i.normalWorld;
	real3 tangentWorld = i.tangentWorld;
				
	BuildSurfaceDirtection( s, normalRGAnsiCosSinBA.xy, tangentWorld, i.bitangent, normalWorld, i.posWorld);

	BuildSurfaceAnisotropy( s, normalRGAnsiCosSinBA.z, normalRGAnsiCosSinBA.w, MetalRoughAOAnisotropyLv.w*_Anisotropy);

		
	MetalRoughAOAnisotropyLv.x = MetalRoughAOAnisotropyLv.x * _Metallic;
	MetalRoughAOAnisotropyLv.y = max(0.02, MetalRoughAOAnisotropyLv.y * _Roughness);
	MetalRoughAOAnisotropyLv.z = MetalRoughAOAnisotropyLv.z * _OcclusionStrength;

	GBufferOutput output	  = (GBufferOutput)0;
		
	output.AlbedoMaterialMask = real4(baseColor, EncodeMaterialID(MaterialID_Anisotropic));
	output.GBuffer1			  = real4(s.normalWorld*0.5 + 0.5,	1.0);
	output.GBuffer2			  = real4(MetalRoughAOAnisotropyLv.xyz,			1.0);
	//output.GBuffer3			  = real4(s.tangentWorld*0.5 + 0.5, s.bitangent.z*0.5 + 0.5);
	output.GBuffer3			  = real4(s.tangentWorld*0.5 + 0.5, s.anisotropyLv);
		
	return output;
}

GBufferOutput GBufferLitClearcoat(Varyings i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	Surface s = (Surface)0;
		
	s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
		
#ifdef USE_HEIGHT_MAP
	float h = SAMPLE_TEXTURE2D_DEF(_HeightMap, i.uv);
	BuildSurfaceUV(s, i.uv, h, _Height, s.viewDir);
#else
	BuildSurfaceUV(s, i.uv);
#endif
		
	real3 baseColor		= SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0).xyz * i.color.xyz * _BaseColor.xyz;
	real3 normalRG		= SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0).xyz;
	real3 MetalRoughAO	= SAMPLE_TEXTURE2D_DEF(_MetalRoughAOTex, s.uv0).xyz;
		
	real3 normalWorld = i.normalWorld;
	real3 tangentWorld = i.tangentWorld;
		
	BuildSurfaceDirtection( s, normalRG.xy, tangentWorld, i.bitangent, normalWorld, i.posWorld);
		
	MetalRoughAO.x = MetalRoughAO.x * _Metallic;
	MetalRoughAO.y = max(0.02, MetalRoughAO.y * _Roughness);
	MetalRoughAO.z = MetalRoughAO.z * _OcclusionStrength;
		
	GBufferOutput output	  = (GBufferOutput)0;
		
	output.AlbedoMaterialMask = real4(baseColor, EncodeMaterialID(MaterialID_Clearcoat));
	output.GBuffer1			  = real4(s.normalWorld*0.5 + 0.5,	1.0);
	output.GBuffer2			  = real4(MetalRoughAO.xyz,			1.0);
	output.GBuffer3			  = real4(MetalRoughAO.xyz,			1.0);
}
	
GBufferOutput GBufferClothFrag(Varyings i)
{
	UNITY_SETUP_INSTANCE_ID(i);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	Surface s = (Surface)0;
		
	s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
#ifdef USE_HEIGHT_MAP
	float h = SAMPLE_TEXTURE2D_DEF(_HeightMap, i.uv);
	BuildSurfaceUV(s, i.uv, h, _Height, s.viewDir);
#else
	BuildSurfaceUV(s, i.uv);
#endif
		
	real3 baseColor		= SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0).xyz * i.color.xyz * _BaseColor.xyz;
	real3 normalRG		= SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0).xyz;
	real3 MetalRoughAO	= SAMPLE_TEXTURE2D_DEF(_MetalRoughAOTex, s.uv0).xyz;
		
	real3 normalWorld = i.normalWorld;
	real3 tangentWorld = i.tangentWorld;
		
	BuildSurfaceDirtection( s, normalRG.xy, tangentWorld, i.bitangent, normalWorld, i.posWorld);
		
	MetalRoughAO.x = MetalRoughAO.x * _Metallic;
	MetalRoughAO.y = max(0.02, MetalRoughAO.y * _Roughness);
	MetalRoughAO.z = MetalRoughAO.z * _OcclusionStrength;
		
	GBufferOutput output	  = (GBufferOutput)0;
		
	output.AlbedoMaterialMask = real4(baseColor, EncodeMaterialID(MaterialID_Cloth));
	output.GBuffer1			  = real4(s.normalWorld*0.5 + 0.5,	1.0);
	output.GBuffer2			  = real4(MetalRoughAO.xyz,			1.0);
	output.GBuffer3			  = _FuzzColorClothLv;
		
	return output;
}
#endif