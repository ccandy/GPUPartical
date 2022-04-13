#ifndef _DEFERRED_LIGHTING_PASS_HLSL_ 
#define _DEFERRED_LIGHTING_PASS_HLSL_

#include "DeferredLightingBuffer.hlsl"

#include "../../BxDF/EnvUtils.hlsl"
#include "../../BxDF/DeferredShading.hlsl"

struct Attributes
{
    float4 vertex   : POSITION;
    float2 uv           : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS    : SV_POSITION;
    float2 screenUV       : TEXCOORD0;
};

real GetDepthFromDepthTexture(real2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD_DEF( _DepthTexture, screenUV, 0).r;
}

 Varyings DeferredLightingVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    
    output.screenUV = UnityStereoTransformScreenSpaceTex(input.uv);
    //output.positionCS =  float4(input.uv.x*2.0 - 1.0, 1.0 - input.uv.y*2.0, 1.0, 1.0);
    output.positionCS = ComputeClipSpacePosition(input.uv, 0);
    
    return output;
}

half4 MainLightingFragment(Varyings input) : SV_Target
{
    real  depth    = GetDepthFromDepthTexture(input.screenUV);
    real4 gbuffer0 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer0, input.screenUV, 0);
    real4 gbuffer1 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer1, input.screenUV, 0);
    real4 gbuffer2 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer2, input.screenUV, 0);
    real4 gbuffer3 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer3, input.screenUV, 0);
    
    real4 posWorld = mul(_ScreenToWorld, float4(input.positionCS.xy, depth, 1));
        
    posWorld.xyz *= rcp(posWorld.w);
            
    int MaterialID = DecodeMaterialID(gbuffer0.w);
        
    real4 col = 0;
    
    real NoL = 0;
    
    Surface s = (Surface)0;
    
    DecodeGBufferToSurface(s, MaterialID, gbuffer0.xyz, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
    
    //return float4(s.bitangent,1);
    //return float4(s.normalWorld,1);
    //return s.anisotropyLv;
    
    Light mainLight = GetMainLight(posWorld.xyz);
    //mainLight.attenuation = gbuffer3.w;
    //return mainLight.attenuation;
    
    FDirectLighting lighting = Lit(mainLight, s, MaterialID);
    col.xyz = lighting.Diffuse + lighting.Specular + lighting.Transmission;
    
    Light addLight;
    addLight.attenuation = 1.0;
    
    UNITY_UNROLL
    for (int i = 0; i < _DirectionalLight_Count; ++i)
    {
        addLight.direction = _DirectionalLight_Directions[i].xyz;
        addLight.color = _DirectionalLight_Colores[i].xyz;
        NoL = max(0, dot(s.normalWorld, addLight.direction));
        lighting = Lit( addLight, s, MaterialID);
        col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
    }
    
    real4 GI = BuildAmbient(s.normalWorld);
		
	col.xyz += GI.xyz * s.diffColor + s.specColor * GI.a * GetInDeferredReflectionLighting(s, GI, MaterialID);
    
    col.w = 1.0;
            
    return MaterialID == 0 ? 0 : col;
}

half4 DirectionalLightingFragment(Varyings input) : SV_Target
{
    real  depth    = GetDepthFromDepthTexture(input.screenUV);
    real4 gbuffer0 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer0, input.screenUV, 0);
    real4 gbuffer1 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer1, input.screenUV, 0);
    real4 gbuffer2 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer2, input.screenUV, 0);
    real4 gbuffer3 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer3, input.screenUV, 0);
    
    real4 posWorld = mul(_ScreenToWorld, float4(input.positionCS.xy, depth, 1));
        
    posWorld.xyz *= rcp(posWorld.w);
            
    int MaterialID = DecodeMaterialID(gbuffer0.w);
        
    real4 col = 0;
    
    real NoL = 0;
    
    Surface s = (Surface)0;
    
    DecodeGBufferToSurface(s, MaterialID, gbuffer0.xyz, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
        
    Light addLight;
    addLight.attenuation = 1.0;
    
    UNITY_UNROLL
    for (int i = 0; i < _DirectionalLight_Count; ++i)
    {
        addLight.direction = _DirectionalLight_Directions[i].xyz;
        addLight.color = _DirectionalLight_Colores[i].xyz;
        NoL = max(0, dot(s.normalWorld, addLight.direction));
        FDirectLighting lighting = Lit( addLight, s, MaterialID);
        col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
    }
                
    return MaterialID == 0 ? 0 : col;
}

half4 PointLightingFragment(Varyings input) : SV_Target
{
    real  depth    = GetDepthFromDepthTexture(input.screenUV);
    real4 gbuffer0 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer0, input.screenUV, 0);
    real4 gbuffer1 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer1, input.screenUV, 0);
    real4 gbuffer2 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer2, input.screenUV, 0);
    real4 gbuffer3 = SAMPLE_TEXTURE2D_LOD_DEF( _GBuffer3, input.screenUV, 0);
    
    real4 posWorld = mul(_ScreenToWorld, float4(input.positionCS.xy, depth, 1));
        
    posWorld.xyz *= rcp(posWorld.w);
            
    int MaterialID = DecodeMaterialID(gbuffer0.w);
        
    real4 col = 0;
    
    real NoL = 0;
    
    Surface s = (Surface)0;
    
    DecodeGBufferToSurface(s, MaterialID, gbuffer0.xyz, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
        
    Light addLight;
    addLight.attenuation = 1.0;
    
    FDirectLighting lighting;
    
    UNITY_UNROLL
    for (int i = 0; i < _PointLight_Count; ++i)
    {
        addLight =  PointLightInit(s, _PointLight_Positions[i].xyz, _PointLight_Range[i], _PointLight_Colores[i].xyz);
        
        NoL = max(0, dot(s.normalWorld, addLight.direction));
        lighting = Lit( addLight, s, MaterialID);
        col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
    }
      
    //return addLight.attenuation;
    //return float4(lighting.Diffuse,1.0);
    return MaterialID == 0 ? 0 : col;
}

#endif