using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
using static UnityEngine.ParticleSystem;

namespace Frameworks.CRP.GPUParticle
{
	[Serializable]
	public class EmissionParam 
	{
		public MinMaxCurve rateOverTime					= 1.0f;
		public MinMaxCurve rateOverDistance				= 0.0f;

		[Min(0.01f)]
		public float	   interval						= 0.01f;

		public MinMaxCurve startVelocity				= 5.0f;

		public bool			IsRandomRotation			= false; 

		public Vector3		startRotation;

		public Vector3		startAcceleration;

		public Vector3		startRev;

		public Vector3		startRotationAcceleration;

		public MinMaxGradient startColor;

		public Vector3 GetStartAcceleration(float time)
		{
			return startAcceleration;
		}

		public Vector3 GetStartRotation(float time)
		{
			return startRotation;
		}

		public Vector3 GetStartRev(float time)
		{
			return startRev;
		}

		public Vector3 GetStartRotationAcceleration(float time)
		{
			return startRotationAcceleration;
		}
	}
}
