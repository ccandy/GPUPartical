#ifndef _BXDF_CONTEXT_HLSL_
#define _BXDF_CONTEXT_HLSL_

#include "../BaseDefine/ConstDefine.hlsl"
#include "../BaseDefine/CommonDefine.hlsl"
#include "BxDFBaseFunction.hlsl"

struct BxDFContext
{
	real NoV;
	real NoL;
	real VoL;
	real NoH;
	real VoH;
};

void InitBxDFContext(inout BxDFContext Context, real3 N, real3 V, real3 L)
{
	Context.NoL = dot(N, L);
	Context.NoV = dot(N, V);
	Context.VoL = dot(V, L);
	real InvLenH = rsqrt(2 + 2 * Context.VoL);
	Context.NoH  = saturate((Context.NoL + Context.NoV) * InvLenH);
	Context.VoH  = saturate(InvLenH + InvLenH * Context.VoL);

	//Context.NoH = max( 0, dot(N, H));
	//Context.VoH = max( 0, dot(V, H));

	//NoL = saturate( NoL );
	//NoV = saturate( abs( NoV ) + 1e-5 );
}

// [ de Carpentier 2017, "Decima Engine: Advances in Lighting and AA" ]
void SphereMaxNoH(inout BxDFContext Context, real SinAlpha, bool bNewtonIteration)
{
	if (SinAlpha > 0)
	{
		float CosAlpha = sqrt(1 - Pow2(SinAlpha));

		float RoL = 2 * Context.NoL * Context.NoV - Context.VoL;
		if (RoL >= CosAlpha)
		{
			Context.NoH = 1;
			Context.VoH = abs(Context.NoV);
		}
		else
		{
			real rInvLengthT = SinAlpha * rsqrt(1 - RoL * RoL);
			real NoTr = rInvLengthT * (Context.NoV - RoL * Context.NoL);
			real VoTr = rInvLengthT * (2 * Context.NoV*Context.NoV - 1 - RoL * Context.VoL);

			if (bNewtonIteration)
			{
				// dot( cross(N,L), V )
				real NxLoV = sqrt(saturate(1 - Pow2(Context.NoL) - Pow2(Context.NoV) - Pow2(Context.VoL) + 2 * Context.NoL * Context.NoV * Context.VoL));

				real NoBr = rInvLengthT * NxLoV;
				real VoBr = rInvLengthT * NxLoV * 2 * Context.NoV;
				real NoLVTr = Context.NoL * CosAlpha + Context.NoV + NoTr;
				real VoLVTr = Context.VoL * CosAlpha + 1 + VoTr;

				real p = NoBr * VoLVTr;
				real q = NoLVTr * VoLVTr;
				real s = VoBr * NoLVTr;

				real xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
				real xDenom = p * p + s * (s - 2 * p) + NoLVTr * ((Context.NoL * CosAlpha + Context.NoV) * Pow2(VoLVTr) + q * (-0.5 * (VoLVTr + Context.VoL * CosAlpha) - 0.5));
				real TwoX1 = 2 * xNum / (Pow2(xDenom) + Pow2(xNum));
				real SinTheta = TwoX1 * xDenom;
				real CosTheta = 1.0 - TwoX1 * xNum;
				NoTr = CosTheta * NoTr + SinTheta * NoBr;
				VoTr = CosTheta * VoTr + SinTheta * VoBr;
			}

			Context.NoL = Context.NoL * CosAlpha + NoTr;
			Context.VoL = Context.VoL * CosAlpha + VoTr;
			real InvLenH = rsqrt(2 + 2 * Context.VoL);
			Context.NoH = saturate((Context.NoL + Context.NoV) * InvLenH);
			Context.VoH = saturate(InvLenH + InvLenH * Context.VoL);
		}
	}
}

#endif