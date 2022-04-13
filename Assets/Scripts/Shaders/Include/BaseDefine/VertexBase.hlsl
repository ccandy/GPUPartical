#ifndef	_VERTEX_BASE_HLSL_
#define _VERTEX_BASE_HLSL_

#include "CommonDefine.hlsl"
#include "../BxDF/BxDFBaseFunction.hlsl"

struct VertexData
{
    real4 posWorld;
    real3 normalWorld;
    real3 bitangent;
    real3 tangentWorld;
    real4 posMVP;
};

// Warning: Do not use UNITY_MATRIX_MV anymore!!!
// Because:
//#define UNITY_MATRIX_MV    mul(UNITY_MATRIX_V, UNITY_MATRIX_M)
//#define UNITY_MATRIX_T_MV  transpose(UNITY_MATRIX_MV)
//#define UNITY_MATRIX_IT_MV transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))
//#define UNITY_MATRIX_MVP   mul(UNITY_MATRIX_VP, UNITY_MATRIX_M)

VertexData BuildVertexData(float4 vertex, float3 normal, float4 tangent)
{
    VertexData data = (VertexData) 0;
    data.posWorld = mul(UNITY_MATRIX_M, vertex);
    
    data.normalWorld = normalize(mul(UNITY_MATRIX_M, float4(normal, 0)).xyz);
    //data.normalWorld = mul(normal, (float3x3)GetWorldToObjectMatrix());
    
    data.tangentWorld = normalize(mul(UNITY_MATRIX_M, float4(tangent.xyz, 0.0)).xyz);
    //data.tangentWorld = mul(tangent.xyz, (float3x3)GetWorldToObjectMatrix());
    
    data.bitangent = normalize(cross(data.normalWorld, data.tangentWorld) * tangent.w * unity_WorldTransformParams.w);
    data.posMVP = mul(UNITY_MATRIX_VP, data.posWorld);
    return data;
}

// Remove bitangent and tangent ALU
VertexData BuildVertexDataSimple(float4 vertex, float3 normal, float4 tangent)
{
    VertexData data = (VertexData) 0;
    data.posWorld = mul(unity_ObjectToWorld, vertex);
    data.normalWorld = mul(unity_ObjectToWorld, float4(normal, 0)).xyz;
    data.posMVP = mul(UNITY_MATRIX_VP, data.posWorld);
    return data;
}


#endif