#ifndef	_SPACE_FUNCTION_HLSL_
#define _SPACE_FUNCTION_HLSL_

// Quaternion multiplication
// http://mathworld.wolfram.com/Quaternion.html
float4 QuaternionMul(float4 q1, float4 q2) // q1 * q2
{
    return float4(q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
float3 QuaternionMulVector(float4 r, float3 v)
{
    float4 r_c = r * float4(-1, -1, -1, 1);
    return QuaternionMul( r, QuaternionMul(float4(v, 0), r_c )).xyz;
}

// Unity Euler C Share Code
float3 QuaternionMulVector01(float4 rotation, float3 v)
{
	float num = rotation.x * 2;
	float num2 = rotation.y * 2;
	float num3 = rotation.z * 2;
	float num4 = rotation.x * num;
	float num5 = rotation.y * num2;
	float num6 = rotation.z * num3;
	float num7 = rotation.x * num2;
	float num8 = rotation.x * num3;
	float num9 = rotation.y * num3;
	float num10 = rotation.w * num;
	float num11 = rotation.w * num2;
	float num12 = rotation.w * num3;
	float3 result;
	result.x = (1 - (num5 + num6)) * v.x + (num7 - num12) * v.y + (num8 + num11) * v.z;
	result.y = (num7 + num12) * v.x + (1 - (num4 + num6)) * v.y + (num9 - num10) * v.z;
	result.z = (num8 - num11) * v.x + (num9 + num10) * v.y + (1 - (num4 + num5)) * v.z;
	return result;
}

// ZXY Quatern like unity
float4 Euler(float3 eulerAngle)
{
    float3 halfAngle = eulerAngle * 0.5;
    
    float cX = cos(halfAngle.x);
    float sX = sin(halfAngle.x);
             
    float cY = cos(halfAngle.y);
    float sY = sin(halfAngle.y);
             
    float cZ = cos(halfAngle.z);
    float sZ = sin(halfAngle.z);
    
    float4 qX = float4(sX, 0.0, 0.0, cX);
    float4 qY = float4(0.0, sY, 0.0, cY);
    float4 qZ = float4(0.0, 0.0, sZ, cZ);
    
    return QuaternionMul( QuaternionMul(qZ, qX), qY);
}

#endif