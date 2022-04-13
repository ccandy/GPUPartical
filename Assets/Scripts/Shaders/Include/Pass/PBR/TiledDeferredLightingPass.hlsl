#ifndef _TILED_DEFERRED_LIGHTING_PASS_HLSL_ 
#define _TILED_DEFERRED_LIGHTING_PASS_HLSL_

#include "TiledDeferredLightingBuffer.hlsl"

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

half4 TiledPointLightingFragment_Procedural(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
        
    int pointLightCount = int(UNITY_MATRIX_M[1].x);
    int lightIndices[8] = { int(UNITY_MATRIX_M[2].x), int(UNITY_MATRIX_M[2].y),int(UNITY_MATRIX_M[2].z), int(UNITY_MATRIX_M[2].w), 
                            int(UNITY_MATRIX_M[3].x), int(UNITY_MATRIX_M[3].y),int(UNITY_MATRIX_M[3].z), int(UNITY_MATRIX_M[3].w),};
        
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
    UNITY_UNROLL
    for (int i = 0; i < pointLightCount && i < 8; ++i)
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


half4 TiledPointLightingFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
        
    //int pitchX = (int)ceil(_TileSize_ResolutionSize.z / _TileSize_ResolutionSize.x);
    //float2 tileUVSize = _TileSize_ResolutionSize.xy / _TileSize_ResolutionSize.zw;
        
    //int y = floor(input.screenUV.y / tileUVSize.y);
    //int x = floor(input.screenUV.x / tileUVSize.x);
        
        
    //return x/120.0;
    
        
        
    int tileIndex = GetTileIndex(input.screenUV);

    uint tileLightCount   = _PointLightTileCount[tileIndex].Count;
    TileLightingInfo tile = _PointLightTileInfo[tileIndex];
        
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
    //UNITY_UNROLL
                    
    UNITY_UNROLL
    for (uint index = 0; index < LIGHTCOUNT_MAX_TILED_LIGHT_COUNT; ++index)
    {
        if (index < tileLightCount)
        {
            uint i = tile.LightIndices[index / 4][index % 4];

            PointLightData pointLight = _AdditionalPointLightData[i];
            addLight = PointLightInit(s, pointLight.Position.xyz, pointLight.Range.x, pointLight.Color.xyz);
            NoL = max(0, dot(s.normalWorld, addLight.direction));
            lighting = Lit(addLight, s, MaterialID);
            col.xyz += lighting.Diffuse + lighting.Specular + lighting.Transmission;
        }        
    }
        
      
    return col;
    //return float4(lighting.Diffuse, 1.0);
    //return MaterialID == 0 ? 0 : col;
}

half4 TiledSimplePointLightingFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
        
    int tileIndex = GetTileIndex(input.screenUV);

    uint tileLightCount   = _PointLightTileCount[tileIndex].Count;
    TileLightingInfo tile = _PointLightTileInfo[tileIndex];
        
    real depth = GetDepthFromDepthTexture(input.screenUV);
    real4 gbuffer0 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer0, input.screenUV, 0);
    real4 gbuffer1 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer1, input.screenUV, 0);
    real4 gbuffer2 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer2, input.screenUV, 0);
    real4 gbuffer3 = SAMPLE_TEXTURE2D_LOD_DEF(_GBuffer3, input.screenUV, 0);
    
    real4 posWorld = mul(_ScreenToWorld, float4(input.positionCS.xy, depth, 1));
        
    posWorld.xyz *= rcp(posWorld.w);
                    
    real4 col = 0;
    
    real NoL = 0;
    
    Surface s = (Surface) 0;
    
    LitDecodeGBufferToSurface(s, gbuffer0.xyz, gbuffer1, gbuffer2, posWorld.xyz);
        
    Light addLight;
    addLight.attenuation = 1.0;
    
    FDirectLighting lighting;
    
    //return (UNITY_MATRIX_M[2].xyzw);
    //UNITY_UNROLL
                    
    UNITY_UNROLL
    //for (int index = 0; index < (int)(tile.Count.x); ++index)
    for (uint index = 0; index < LIGHTCOUNT_MAX_TILED_LIGHT_COUNT; ++index)
    {
        if (index < tileLightCount)
        {
            uint i = tile.LightIndices[index / 4][index % 4];

            PointLightData pointLight = _AdditionalPointLightData[i];
            addLight = PointLightInit(s, pointLight.Position.xyz, pointLight.Range.x, pointLight.Color.xyz);
            //NoL = max(0, dot(s.normalWorld, addLight.direction));
            lighting = SimpleLit(addLight, s);
            col.xyz += lighting.Diffuse + lighting.Specular;
        }        
    }

    return col;
}

#endif