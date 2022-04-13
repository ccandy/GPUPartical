#ifndef _BXDF_BASE_FUNCTION_HLSL_
#define _BXDF_BASE_FUNCTION_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"

real Pow2(real x)
{
	return x * x;
}

real2 Pow2(real2 x)
{
	return x * x;
}

real3 Pow2(real3 x)
{
	return x * x;
}

real4 Pow2(real4 x)
{
	return x * x;
}

real Pow3(real x)
{
	return x * x*x;
}

real2 Pow3(real2 x)
{
	return x * x*x;
}

real3 Pow3(real3 x)
{
	return x * x*x;
}

real4 Pow3(real4 x)
{
	return x * x*x;
}

//real Pow4(real x)
//{
//	real xx = x * x;
//	return xx * xx;
//}

real2 Pow4(real2 x)
{
	real2 xx = x * x;
	return xx * xx;
}

real3 Pow4(real3 x)
{
	real3 xx = x * x;
	return xx * xx;
}

real4 Pow4(real4 x)
{
	real4 xx = x * x;
	return xx * xx;
}

real Pow5(real x)
{
	real xx = x * x;
	return xx * xx * x;
}

real2 Pow5(real2 x)
{
	real2 xx = x * x;
	return xx * xx * x;
}

real3 Pow5(real3 x)
{
	real3 xx = x * x;
	return xx * xx * x;
}

real4 Pow5(real4 x)
{
	real4 xx = x * x;
	return xx * xx * x;
}

real Pow6(real x)
{
	real xx = x * x;
	return xx * xx * xx;
}

real2 Pow6(real2 x)
{
	real2 xx = x * x;
	return xx * xx * xx;
}

real3 Pow6(real3 x)
{
	real3 xx = x * x;
	return xx * xx * xx;
}

real4 Pow6(real4 x)
{
	real4 xx = x * x;
	return xx * xx * xx;
}

real Square(real x)
{
	return x * x;
}

real2 Square(real2 x)
{
	return x * x;
}

real3 Square(real3 x)
{
	return x * x;
}

real3 RGBMDecode(real4 rgbm, real MaxValue)
{
	return rgbm.rgb * (rgbm.a * MaxValue);
}

// Unity Default RGBM Decode
real3 RGBMDecode(real4 rgbm)
{
	return rgbm.rgb * (rgbm.a * 5.0);
}


real3 ACESFilm(real3 x)
{
	real a = 2.51;
	real b = 0.03;
	real c = 2.43;
	real d = 0.59;
	real e = 0.14;
	return saturate((x*(a*x + b)) / (x*(c*x + d) + e));
}

// UE4.2 SmoothStep
real SmoothMin(real a, real b, real k)
{
	real h = saturate(0.5 + (0.5 / k) * (b - a));
	return lerp(b, a, h) - k * (h - h * h);
}

real SmoothMax(real a, real b, real k)
{
	return SmoothMin(a, b, -k);
}

real SmoothClamp(real x, real Min, real Max, real k)
{
	return SmoothMin(SmoothMax(x, Min, k), Max, k);
	//return min( max( x, Min ), Max );
}



// use in vertex shader
real3 VertexNormalize(real3 v)
{
#if defined(USE_PIXEL_NORMALIZE)
	return v;
#else
	return normalize(v);
#endif
}

// use in pixel shader
real3 PixelNormalize(real3 v)
{
#if defined(USE_PIXEL_NORMALIZE)
	return normalize(v);
#else
	return v;
#endif
}


real GammaToLinearSpaceExact(real value)
{
	if (value <= 0.04045F)
		return value / 12.92F;
	else if (value < 1.0F)
		return pow((value + 0.055F) / 1.055F, 2.4F);
	else
		return pow(value, 2.2F);
}

real3 GammaToLinearSpace(real3 sRGB)
{
	// Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
	return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

	// Precise version, useful for debugging.
	//return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}

real LinearToGammaSpaceExact(real value)
{
	if (value <= 0.0)
		return 0.0;
	else if (value <= 0.0031308)
		return 12.92 * value;
	else if (value < 1.0)
		return 1.055 * pow(value, 0.4166667) - 0.055;
	else
		return pow(value, 0.45454545);
}

real3 LinearToGammaSpace(real3 linRGB)
{
	linRGB = max(linRGB, 0.0);
	// An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
	return max(1.055h * pow(linRGB, 0.416666667) - 0.055, 0);

	// Exact version, useful for debugging.
	//return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));
}

// Return the ith number from fibonacci sequence.
real Fibonacci1D(int i)
{
	return frac((real(i) + 1.0) * M_GOLDEN_RATIO);
}

// Return the ith couple from the fibonacci sequence.nbSample is required to get an uniform distribution.
real2 Fibonacci2D(int i, int nbSamples)
{
	return real2(
		(real(i) + 0.5) / real(nbSamples),
		Fibonacci1D(i)
	);

	//return (real(i) + 0.5) / real(nbSamples) * Fibonacci1D(i);
}

real Luminance_(real3 color)
{
	return dot(color, real3(0.3, 0.59, 0.11));
}

real MaxValue(real3 color)
{
	return max(color.r, max(color.g, color.b));
}

real length2(real2 v)
{
	return dot(v, v);
}

real length2(real3 v)
{
	return dot(v, v);
}

real length2(real4 v)
{
	return dot(v, v);
}

uint Mod(uint a, uint b)
{
#if (SHADER_TARGET >= 40)
	return a % b;
#else
	return a - (b * (uint)((float)a / (float)b));
#endif
}

uint2 Mod(uint2 a, uint2 b)
{
#if (SHADER_TARGET >= 40)
	return a % b;
#else
	return a - (b * (uint2)((float2)a / (float2)b));
#endif
}

uint3 Mod(uint3 a, uint3 b)
{
#if (SHADER_TARGET >= 40)
	return a % b;
#else
	return a - (b * (uint3)((float3)a / (float3)b));
#endif
}

real UnClampedPow(real X, real Y)
{
	return pow(X, Y);
}
real2 UnClampedPow(real2 X, real2 Y)
{
	return pow(X, Y);
}
real3 UnClampedPow(real3 X, real3 Y)
{
	return pow(X, Y);
}
real4 UnClampedPow(real4 X, real4 Y)
{
	return pow(X, Y);
}

// Clamp the base, so it's never <= 0.0f (INF/NaN).
real ClampedPow(real X, real Y)
{
	return pow(max(abs(X), 0.000001f), Y);
}
real2 ClampedPow(real2 X, real2 Y)
{
	return pow(max(abs(X), real2(0.000001f, 0.000001f)), Y);
}
real3 ClampedPow(real3 X, real3 Y)
{
	return pow(max(abs(X), real3(0.000001f, 0.000001f, 0.000001f)), Y);
}
real4 ClampedPow(real4 X, real4 Y)
{
	return pow(max(abs(X), real4(0.000001f, 0.000001f, 0.000001f, 0.000001f)), Y);
}

real PositiveClampedPow(real X, real Y)
{
	return pow(max(X, 0.0f), Y);
}
real2 PositiveClampedPow(real2 X, real2 Y)
{
	return pow(max(X, real2(0.0f, 0.0f)), Y);
}
real3 PositiveClampedPow(real3 X, real3 Y)
{
	return pow(max(X, real3(0.0f, 0.0f, 0.0f)), Y);
}
real4 PositiveClampedPow(real4 X, real4 Y)
{
	return pow(max(X, real4(0.0f, 0.0f, 0.0f, 0.0f)), Y);
}

real PhongShadingPow(real X, real Y)
{
	// The following clamping is done to prevent NaN being the result of the specular power computation.
	// Clamping has a minor performance cost.

	// In HLSL pow(a, b) is implemented as exp2(log2(a) * b).

	// For a=0 this becomes exp2(-inf * 0) = exp2(NaN) = NaN.

	// As seen in #TTP 160394 "QA Regression: PS3: Some maps have black pixelated artifacting."
	// this can cause severe image artifacts (problem was caused by specular power of 0, lightshafts propagated this to other pixels).
	// The problem appeared on PlayStation 3 but can also happen on similar PC NVidia hardware.

	// In order to avoid platform differences and rarely occuring image atrifacts we clamp the base.

	// Note: Clamping the exponent seemed to fix the issue mentioned TTP but we decided to fix the root and accept the
	// minor performance cost.

	return ClampedPow(X, Y);
}

#endif