#ifndef _PARTICLE_INSTANCED_DEFINE_HLSL_
#define _PARTICLE_INSTANCED_DEFINE_HLSL_

#include "../../Include/BaseDefine/ConstDefine.hlsl"
#include "../../Include/BaseDefine/CommonDefine.hlsl"


#include "GPUParticleFunction.hlsl"

int  _InstanceOffset;
int  _MeshVerticesCount;
int  _MeshCountPerGroup;
float4 _ParticleEmitterPosition;
float4 _ParticleEmitterRotator;

float4 _ParticleBaseParam;	
float4 _ParticleEmitterParam;
float4 _ParticleLifeParam;	
float4 _ParticleVelocityParam;
float4 _ParticleAccelerationParam;

TEXTURE2D_DEF(_InPositionTexture);
TEXTURE2D_DEF(_InVelocityTexture);
TEXTURE2D_DEF(_InSpinTexture);

uint GetRealInstanceID(uint instanceID, uint vIndex)
{
	return _InstanceOffset + instanceID*_MeshCountPerGroup + floor(vIndex / (float)_MeshVerticesCount);
}

float2 InstanceIDToUV(uint instanceID, uint vIndex, out float isOutOfRange)
{
	uint realInstanceID = GetRealInstanceID(instanceID, vIndex);
	
	isOutOfRange = step(realInstanceID,_ParticleBaseParam.x);
	
	return IDToUV(realInstanceID, _ParticleBaseParam.w);
}

float4 GetVertex(float4 vertex, float2 uvForData)
{
	float4 posTime = SAMPLE_TEXTURE2D_LOD_DEF( _InPositionTexture, uvForData, 0);
	
	vertex.xyz = mul(float3x3(UNITY_MATRIX_I_V[0].xyz,UNITY_MATRIX_I_V[1].xyz,UNITY_MATRIX_I_V[2].xyz), vertex.xyz);
	
	vertex.xyz += posTime.xyz;
	
	vertex.w = posTime.w;
	
	return vertex;
}


//void GetVertexInstanceInfo(uint instanceID, float4 vertex, float4 color, out float4 MVPPos, out float color)
//{
//	float4 startColor		 = UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties,  _StartColor);
//	float4 startPosition_Time = UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties, _StartPosition_Time);
//	float3 startAcceleration  = UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties, _StartAcceleration).xyz;

	
//	float4 position			 = float4(0,0,0,1);
//	#if ENABLE_BILLBOARD
//	position.xyz = vertex.xyz + startPosition_Time.w * startPosition_Time.xyz
//				+ 0.5f * _startAcceleration * startPosition_Time.w * startPosition_Time.w;

//	position = mul(UNITY_MATRIX_P, position);
//	#else
	
//	float4x4 worldMatrix;

//	float3 startRotation			= UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties, _StartRotation).xyz;
//	float3 startRev					= UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties, _StartRev).xyz;
//	float3 startRotationAcceleration= UNITY_ACCESS_INSTANCED_PROP(PartilceInstancingProperties, _StartRotationAcceleration).xyz;
	
//	float3 rotator					= fmod(startRotation + startPosition_Time.w * startRev
//										+ 0.5f * startRotationAcceleration * startPosition_Time.w * startPosition_Time.w, M_2PI);

//	float3 rotationSin				= sin(rotator);
//	float3 rotationCos				= cos(rotator);

//	float3x3 rotation;
//	rotation._11_21_31				= float3(1,0,0);
//	rotation._12_22_32				= float3(0,1,0);
//	rotation._13_23_33				= float3(0,0,1);

//	rotation = mul( float3x3(rotationCos.z, rotationSin.z, 0,
//							 -rotationSin.z, rotationCos.z, 0,
//							 0,  0,  1			)  , rotation);

//	rotation = mul( float3x3(0,  0,  1,
//							 0, rotationCos.x, rotationSin.x, 
//							 0, -rotationSin.x, rotationCos.x), rotation);

//	rotation = mul( float3x3(rotationCos.y, 0, rotationSin.y, 
//							0,  0,  1,	 
//							-rotationSin.y, 0, rotationCos.y ) , rotation);

//	position = mul(float4x4(rotation._11_21_31, 0,
//						  rotation._12_22_32, 0,
//						  rotation._13_23_33, 0,
//						  0,0,0,1),				vertex);

//	position.xyz = position.xyz + startPosition_Time.w * startPosition_Time.xyz
//				+ 0.5f * startAcceleration * startPosition_Time.w * startPosition_Time.w;

//	position = mul(UNITY_MATRIX_VP, position);
//	#endif

//	return position;
//}


#endif