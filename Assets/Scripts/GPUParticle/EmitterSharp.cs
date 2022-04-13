using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Frameworks.CRP.GPUParticle
{
	[Serializable]
	public class EmitterSharpParam
	{
		public enum SharpType
		{
			Cone,
			Box,
			Sphere,
		}

		public SharpType sharp;

		public float radius = 1.0f;

		public float radiusThickness = 1.0f;

		public float angleDegree = 20.0f;

		public float arcDegree = 360f;
	}
}
