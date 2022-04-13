using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
using static UnityEngine.ParticleSystem;

namespace Frameworks.CRP.GPUParticle
{
	[Serializable]
	public class EmitterColor
	{
		public bool		EnableColorOverLife = false;
		public Gradient ColorOverLife		= new Gradient();

		public bool		nableColorOverSpeed = false;
		public Gradient ColorOverSpeed		= new Gradient();
		public Vector2  SpeedRange			= Vector2.up;
	}
}
