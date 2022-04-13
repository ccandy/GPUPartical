#ifndef _GPU_PARTICLE_FUNCTION_HLSL_
#define	_GPU_PARTICLE_FUNCTION_HLSL_

#include "../../Include/BaseDefine/ConstDefine.hlsl"
#include "../../Include/BaseDefine/Random.hlsl"
#include "../../Include/BaseDefine/SpaceFunction.hlsl"


#define EMITTER_CONE 0
#define EMITTER_BOX  1

uint2 IDToInt2(uint id, float pitchX)
{
	uint2 uUV;
	uUV.x = id%pitchX;
	uUV.y = id/pitchX;
	
	return uUV;
}

float2 IDToUV(uint id, float2 pitch)
{
	float2 uv;
	uv.x = fmod(id, pitch.x);
	uv.y = ((float)(id - uv.x)) / pitch.x / pitch.y;
	uv.x /= pitch.x;
	
	return uv;
}

void EmitterCone(inout float3 position, inout float3 direction,
					float2 uv,
					float randomSeed,
					float radius, float radiusThickness, float angleDegree, float arcDegree)
{	
	float emitterRoundRad = randomRange(0, arcDegree, uv, float2( randomSeed, 7) ) * M_DEG_TO_RAD;

	float radiusPercent =  randomRange( (1.0f - radiusThickness), 1.0, uv, float2( randomSeed, 8) );
	
	//float emitterRad = randomRange(0, angleDegree, uv, float2( randomSeed, 6)) * M_DEG_TO_RAD;
	
	float emitterRad = lerp(0, angleDegree, radiusPercent) * M_DEG_TO_RAD;
	
	float emitterRadius =  radiusPercent * radius;

	float3 hRotator = float3(cos(emitterRoundRad), 0.0f, sin(emitterRoundRad));
	
	position = hRotator * emitterRadius;

	float3 vRotator = float3( 0.0, cos(emitterRad), sin(emitterRad));
	
	if (emitterRadius <= 0.001)
	{
		direction = float3(0,1,0);
	}
	else
		direction = vRotator;
	
	direction.x = direction.z * hRotator.x;
	direction.z = direction.z * hRotator.z;
}

void EmitterBox(inout float3 position, inout float3 direction,
					float2 uv,
					float randomSeed,
					float XExtend, float YExtend, float ZExtend)
{
	position.x = randomRange(-XExtend, XExtend, uv, float2( randomSeed, 7));
	position.y = randomRange(-YExtend, YExtend, uv, float2( randomSeed, 8));
	position.z = randomRange(-ZExtend, ZExtend, uv, float2( randomSeed, 9));
	
	direction = float3(0,1,0);
}

float3 GetRotationAxis(float2 uv)
{
    // Uniformaly distributed points
    // http://mathworld.wolfram.com/SpherePointPicking.html

    float u = randomRange( 0, 1, uv, 10) * 2 - 1;
    float theta = randomRange( 0, M_2PI, uv, 11);
    float u2 = sqrt(1 - u * u);
    return float3(u2 * cos(theta), u2 * sin(theta), u);
}

float4 InitParticleRotation(float2 uv)
{
    // Uniform random unit quaternion
    // http://www.realtimerendering.com/resources/GraphicsGems/gemsiii/urot.c
    float r = nrand(uv, 3);
    float r1 = sqrt(1.0 - r);
    float r2 = sqrt(r);
    float t1 = M_2PI * 2 * nrand(uv, 4);
    float t2 = M_2PI * 2 * nrand(uv, 5);
    return float4(sin(t1) * r1, cos(t1) * r1, sin(t2) * r2, cos(t2) * r2);
}


void EmitterParticle(int sharpType, float2 lifeParam, float2 uv, float randomSeed, 
					float4 _emitterParam, 
					float2 speedParam,					
					float2 spinParam,
					inout float4 positionLife, inout float4 velocity)
{
	positionLife.w = randomRange(lifeParam.x, lifeParam.y, uv, float2(randomSeed, 2)) + 0.5;
	
	positionLife.w = clamp(positionLife.w, 0, lifeParam.y);
    
	if (sharpType == EMITTER_CONE)
	{
		EmitterCone(positionLife.xyz, velocity.xyz, uv, randomSeed,
			_emitterParam.x, _emitterParam.y, _emitterParam.z, _emitterParam.w);
	}
	else if (sharpType == EMITTER_BOX)
	{
		EmitterBox(positionLife.xyz, velocity.xyz, uv, randomSeed, 
					_emitterParam.x, _emitterParam.y, _emitterParam.z);
	}
	
	velocity.w = positionLife.w;
	
	float speed = randomRange(speedParam.x, speedParam.y, uv, float2(randomSeed, 3));
	
	velocity.xyz *= speed;
}

float UpdateLife(float curLife, float deltaTime)
{
	return curLife - deltaTime;//max( 0, curLife - deltaTime);
}

float GetLifePercent(float curLife, float totalLife)
{
	return clamp(1.0 - curLife/totalLife, 0.0, 1.0);
}

void UpdatePosition(float deltaTime, inout float3 position, inout float4 velocity, float3 Acceleration)
{
	position += velocity.xyz * deltaTime + deltaTime*deltaTime*Acceleration*0.5;
	velocity.xyz += Acceleration*deltaTime;
}

void UpdateSpin(float deltaTime, inout float4 rotator, float2 uv, float spinSpeed, float spinSpeedFromMoving, float4 velocity, float SpinRandomness)
{
	float theta = (spinSpeed + length(velocity.xyz) * spinSpeedFromMoving) * deltaTime;
	
	theta *= 1.0 - randomRange( 0, M_2PI, uv, 13) * SpinRandomness;
	
	float4 dq = float4( GetRotationAxis(uv) * sin(theta), cos(theta));
}

#endif