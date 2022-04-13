#ifndef _RANDOM_HLSL_
#define _RANDOM_HLSL_

float nrand(float2 uv, float2 seed)
{
    uv += seed;
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float randomRange(float a, float b, float2 uv, float2 seed)
{
    return lerp( a, b, nrand(uv, seed));
}

float worleyNoise(float2 uv)
{
   float2 index = floor(uv);
   float2 pos = frac(uv);
   float d = 1.5;
   for(int i = -1; i < 1; i++)
       for (int j = -1; j < 1; j++)
       {
          float2 p = nrand( uv, index + float2(i, j));
          float dist = length(p + float2(i, j) - pos);
          d = min(dist, d);
       }
   return d;
}

#endif