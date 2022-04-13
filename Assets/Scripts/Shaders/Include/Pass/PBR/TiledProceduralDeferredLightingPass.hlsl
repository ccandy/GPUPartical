#ifndef _TILED_PROCEDURAL_DEFERRED_LIGHTING_PASS_HLSL_ 
#define _TILED_PROCEDURAL_DEFERRED_LIGHTING_PASS_HLSL_

#include "TiledProceduralDeferredLightingBuffer.hlsl"

#include "../../BxDF/EnvUtils.hlsl"
#include "../../BxDF/DeferredShading.hlsl"

struct Attributes
{
    float4 vertex       : POSITION;
    float2 uv           : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS    : SV_POSITION;
    float2 screenUV       : TEXCOORD0;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};
    
struct ProceduralAttributes
{
    uint vertexID : SV_VertexID;
};
    
struct ProceduralVaryings
{
    float4 positionCS    : SV_POSITION;
    float2 screenUV      : TEXCOORD0;
    int tiledIndex       : TEXCOORD1;
};
    
real GetDepthFromDepthTexture(real2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD_DEF( _DepthTexture, screenUV, 0).r;
}

 Varyings DeferredLightingVertex(Attributes input)
{
    Varyings output = (Varyings)0;
        
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    output.screenUV = UnityStereoTransformScreenSpaceTex(input.uv);
    //output.positionCS =  float4(input.uv.x*2.0 - 1.0, 1.0 - input.uv.y*2.0, 1.0, 1.0);
    output.positionCS = ComputeClipSpacePosition(input.uv, 0);
    
    return output;
}
    
 Varyings TiledDeferredLightingVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
        
    Varyings output = (Varyings)0;
        
    UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        
    float4x4 tileData = UNITY_MATRIX_M;
        
    float2 uv = input.uv * tileData[0].xy + tileData[0].zw;
           
    output.screenUV = UnityStereoTransformScreenSpaceTex(uv);
    output.positionCS = ComputeClipSpacePosition(uv, 0);
    
    return output;
}
    
ProceduralVaryings TiledProceduralVertex(ProceduralAttributes input)
{
    ProceduralVaryings output = (ProceduralVaryings)0;
        
    int tiledIndex  = GeTileID(input.vertexID);
        
    float2 uv       = GeTileQuadTexCoord(input.vertexID);
        
    float4 screenSizeTiling = _TileDataOfPointLights[tiledIndex][0];
        
    uv = uv * screenSizeTiling.xy + screenSizeTiling.zw;

    output.screenUV = UnityStereoTransformScreenSpaceTex(uv);
    //output.positionCS =  float4(input.uv.x*2.0 - 1.0, 1.0 - input.uv.y*2.0, 1.0, 1.0);
    output.positionCS = ComputeClipSpacePosition(uv, 0);
        
    output.tiledIndex = tiledIndex;
    
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
    
    Light mainLight = GetMainLight(posWorld.xyz);
    
    FDirectLighting lighting = Lit(mainLight, s, MaterialID);
    col.xyz = lighting.Diffuse + lighting.Specular + lighting.Transmission;
    
    Light addLight;
    addLight.attenuation = 1.0;
    
    //UNITY_UNROLL
    for (int i = 0; i < _DirectionalLight_Count; ++i)
    {
        DirectionLightData directionLight = _AdditionalDiretcionLightData[i];
        addLight.direction = directionLight.Direction.xyz;
        addLight.color = directionLight.Color.xyz;
        NoL = max(0, dot(s.normalWorld, addLight.direction));
        lighting = Lit( addLight, s, MaterialID);
        col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
    }
    
    real4 GI = BuildAmbient(s.normalWorld);
		
	col.xyz += GI.xyz * s.diffColor + s.specColor * GI.a * GetInDeferredReflectionLighting(s, GI, MaterialID);
    
    col.w = 1.0;
            
    return MaterialID == 0 ? 0 : col;
}

half4 TiledPointLightingFragment(ProceduralVaryings input) : SV_Target
{
    float4 tileLightIndices0 = _TileDataOfPointLights[input.tiledIndex][2];
    float4 tileLightIndices1 = _TileDataOfPointLights[input.tiledIndex][3];
    int pointLightCount = int(_TileDataOfPointLights[input.tiledIndex][1].x);
    int lightIndices[8] = { int(tileLightIndices0.x), int(tileLightIndices0.y),int(tileLightIndices0.z), int(tileLightIndices0.w), 
                            int(tileLightIndices1.x), int(tileLightIndices1.y),int(tileLightIndices1.z), int(tileLightIndices1.w),};
        
    real depth = GetDepthFromDepthTexture(input.screenUV);
    real4 gbuffer0 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer0, input.screenUV, 0);
    real4 gbuffer1 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer1, input.screenUV, 0);
    real4 gbuffer2 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer2, input.screenUV, 0);
    real4 gbuffer3 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer3, input.screenUV, 0);
    
    real4 posWorld = mul(_ScreenToWorld, float4(input.positionCS.xy, depth, 1));
        
    posWorld.xyz *= rcp(posWorld.w);
            
    int MaterialID = DecodeMaterialID(gbuffer0.w);
        
    real4 col = 0;
    
    real NoL = 0;
    
    Surface s = (Surface) 0;
    
    DecodeGBufferToSurface(s, MaterialID, gbuffer0.xyz, gbuffer1, gbuffer2, gbuffer3, posWorld.xyz);
        
    Light addLight;
    addLight.attenuation = 1.0;
    
    FDirectLighting lighting;
    
    //return (UNITY_MATRIX_M[2].xyzw);
    for (int i = 0; i < pointLightCount; ++i)
    {
        //if (lightIndices[i] == 0)
        //      continue;
        PointLightData pointLight = _AdditionalPointLightData[lightIndices[i]];
        addLight = PointLightInit(s, pointLight.Position.xyz, pointLight.Range.x, pointLight.Color.xyz);
        NoL = max(0, dot(s.normalWorld, addLight.direction));
        lighting = Lit(addLight, s, MaterialID);
        col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
            
        // col.xyz += pointLight.Color;
    }
      
    return col;
    //return float4(lighting.Diffuse, 1.0);
    //return MaterialID == 0 ? 0 : col;
}

#endif