#ifndef _OIT_PASS_HLSL_
#define _OIT_PASS_HLSL_

#include "OITBuffer.hlsl"
#include "../../BaseDefine/LightingBase.hlsl"
#include "../../BaseDefine/ShadowBase.hlsl"
#include "../../BaseDefine/VertexBase.hlsl"
#include "../../BaseDefine/SurfaceBase.hlsl"

struct Attributes
{
    float4 vertex  : POSITION;
    float4 color   : COLOR0;
    float3 normal  : NORMAL0;
    float4 tangent : TANGENT0;
    float2 uv0     : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    real4  color        : TEXCOORD1;
    real3  normalWorld  : TEXCOORD2;
    real3  tangentWorld : TEXCOORD3;
    real3  bitangent    : TEXCOORD4;
    real3  posWorld     : TEXCOORD5;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
    
Varyings OITLitVert(Attributes v)
{
    Varyings o = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(UNITY_MATRIX_M, v.vertex);
        
    float4 posMVP   = mul(UNITY_MATRIX_VP, posWorld);
        
    VertexData vData = BuildVertexData(v.vertex, v.normal, v.tangent);
        
    o.uv				= TRANSFORM_TEX(v.uv0, _BaseMap);
	o.tangentWorld.xyz	= vData.tangentWorld.xyz;
	o.bitangent.xyz		= vData.bitangent.xyz;
	o.normalWorld.xyz	= vData.normalWorld.xyz;
	o.posWorld.xyz		= vData.posWorld.xyz;
	o.positionCS		= vData.posMVP;
	o.color				= v.color;

    return o;
}
  
real4 OITLitFrag(Varyings i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    Surface s = (Surface)0;
        
    s.uv0 = i.uv;
               
    s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
        
    real4 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0.xy) * i.color * _BaseColor;

#ifdef USE_NORMAL_MAP
	real4 normalRGAnsioBA = SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0);
#else
	real4 normalRGAnsioBA = 0.5;
#endif
        
    BuildSurfaceDirtection( s, normalRGAnsioBA.xy, i.tangentWorld, i.bitangent, i.normalWorld, i.posWorld);
        
    Light l = GetMainLight(s.posWorld);
		
	real NoL = max(0,dot(s.normalWorld, l.direction));
        
    // Simple Lit
    real4 col = baseColor.a;
   
    col.xyz = l.color * baseColor.rgb * NoL * (1.0 + max(0,dot(s.normalWorld, normalize(l.direction + s.viewDir) )));

    return 	OITFirstPassCol(i.positionCS, col);
}
    
real4 OITLitSubPassFrag(Varyings i) : SV_TARGET
{
    
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    Surface s = (Surface)0;
        
    s.uv0 = i.uv;
               
    s.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
        
    real4 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, s.uv0.xy) * i.color * _BaseColor;

#ifdef USE_NORMAL_MAP
	real4 normalRGAnsioBA = SAMPLE_TEXTURE2D_DEF(_NormalTex, s.uv0);
#else
	real4 normalRGAnsioBA = 0.5;
#endif
        
    BuildSurfaceDirtection( s, normalRGAnsioBA.xy, i.tangentWorld, i.bitangent, i.normalWorld, i.posWorld);
        
    Light l = GetMainLight(s.posWorld);
		
	real NoL = max(0,dot(s.normalWorld, l.direction));
        
    // Simple Lit
    real4 col = baseColor.a;
   
    col.xyz = l.color * baseColor.rgb * NoL *  (1.0 + max(0,dot(s.normalWorld, normalize(l.direction + s.viewDir) )));

    return 	OITSubPassCol(i.positionCS, col);
}

struct UnlitAttributes
{
    float4 vertex  : POSITION;
    float4 color   : COLOR0;
    float2 uv0     : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct UnlitVaryings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    real4  color        : TEXCOORD1;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
    
UnlitVaryings OITUnlitVert(UnlitAttributes v)
{
    UnlitVaryings o = (UnlitVaryings) 0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float4 posWorld = mul(UNITY_MATRIX_M, v.vertex);
        
    float4 posMVP   = mul(UNITY_MATRIX_VP, posWorld);
                
    o.uv				= TRANSFORM_TEX(v.uv0, _BaseMap);
	o.positionCS		= posMVP;
	o.color				= v.color;

    return o;
}
        
real4 OITUnlitFrag(Varyings i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        
    float2 uv0 = i.uv;
 
    real4 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, uv0.xy) * i.color * _BaseColor;

    return 	OITFirstPassCol(i.positionCS, baseColor);
}
        
real4 OITUnlitSubPassFrag(Varyings i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        
    float2 uv0 = i.uv;
 
    real4 baseColor = SAMPLE_TEXTURE2D_DEF(_BaseMap, uv0.xy) * i.color * _BaseColor;

    return 	OITSubPassCol(i.positionCS, baseColor);
}

#endif