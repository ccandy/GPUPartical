#ifndef _FORWARD_PASS_HLSL_
#define _FORWARD_PASS_HLSL_

#include "ForwardBuffer.hlsl"
#include "../../BaseDefine/LightingBase.hlsl"
#include "../../BaseDefine/ShadowBase.hlsl"
#include "../../BaseDefine/VertexBase.hlsl"
#include "../../BaseDefine/SurfaceBase.hlsl"
#include "../../BxDF/EnvUtils.hlsl"
#include "../../BxDF/MixShading.hlsl"

struct Attributes
{
	float4 vertex			: POSITION;
	float2 uv0				: TEXCOORD0;
	float2 uv1				: TEXCOORD1;
	float3 normal			: NORMAL;
	float4 tangent			: TANGENT;
	float4 color			: COLOR;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	real4 positionCS	: SV_POSITION;
	real4 uv			: TEXCOORD0;
	real4 color			: TEXCOORD1;
	real3 tangentWorld	: TEXCOORD2;
	real3 bitangent		: TEXCOORD3;
	real3 normalWorld	: TEXCOORD4;
	real3 posWorld		: TEXCOORD5;

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
	
Varyings LitVert(Attributes v)
{
	Varyings o = (Varyings)0;

	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	VertexData vData = BuildVertexData(v.vertex, v.normal, v.tangent);

	o.uv.xy				= TRANSFORM_TEX(v.uv0, _BaseMap);
	o.uv.zw				= v.uv1;
	o.color				= v.color;
	o.tangentWorld.xyz	= vData.tangentWorld.xyz;
	o.bitangent.xyz		= vData.bitangent.xyz;
	o.normalWorld.xyz	= vData.normalWorld.xyz;
	o.posWorld			= vData.posWorld.xyz;
	o.positionCS		= vData.posMVP;

	return o;
}

real4 LitFrag(Varyings i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

	Surface s = (Surface)0;
		
	s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
		
#if defined(USE_HEIGHT_MAP)
	float h = SAMPLE_TEXTURE2D_DEF(_HeightMap, i.uv.xy).x;
	BuildSurfaceUV(s, i.uv.xy, h, _Height, s.viewDir);
#else
	BuildSurfaceUV(s, i.uv.xy);
#endif
		
	real4 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0.xy) * i.color * _BaseColor;

#ifdef USE_NORMAL_MAP
	real4 normalRGAnsioBA = SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0);
#else
	real4 normalRGAnsioBA = 0.5;
#endif

	real4 MetalRoughAO = SAMPLE_TEXTURE2D_DEF(_MetalRoughAOTex, s.uv0);
		
	BuildSurfaceDirtection( s, normalRGAnsioBA.xy, i.tangentWorld, i.bitangent, i.normalWorld, i.posWorld);
	
	real4 GI = BuildAmbient(s.normalWorld);//real4(0.125, 0.125, 0.25, 1);// _EnvCol;
		
	BuildSurfaceColor(s, baseColor.xyz, baseColor.a, GI, MetalRoughAO.g * _Roughness, MetalRoughAO.r*_Metallic, MetalRoughAO.b*_OcclusionStrength, 0.01);
			
#if defined(USE_ANISOTROPIC)
	BuildSurfaceAnisotropy( s, normalRGAnsioBA.b, normalRGAnsioBA.a, _Anisotropy);
#endif
		
		
	Light l = GetMainLight(s.posWorld);
		
	real NoL = max(0,dot(s.normalWorld, l.direction));
				
	FDirectLighting lighting = MixLit(s, s.normalWorld, s.viewDir, NoL, l);
		
	real4 col = baseColor.a;
	col.xyz = lighting.Diffuse + lighting.Specular + lighting.Transmission;
		
	//return float4(s.normalWorld,1);
	col.xyz += GI.xyz * s.diffColor + s.specColor * GI.a * GetReflectionLighting(s, GI);	
	
    return col;
}
#endif