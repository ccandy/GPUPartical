using System;
using System.Collections.Generic;
using UnityEditor;
using Frameworks;
using UnityEngine;

namespace Frameworks.CRP.GPUParticle
{
	[CanEditMultipleObjects]
	[CustomEditor(typeof(ParticleRenderer), true)]
	public class ParticleRendererEditor : Editor
	{
#if UNITY_EDITOR
		static SavedBool isShowEmitterSharp;
		static SavedBool isShowEmitter;
		static SavedBool isShowRenderer;
		static SavedBool isShowTexture;

		SerializedProperty rateOverTimeProp;
		SerializedProperty rateOverDistanceProp;
		SerializedProperty intervalProp;

		SerializedProperty IsRandomRotationProp;
		SerializedProperty startRotationProp;
		SerializedProperty startAccelerationProp;
		SerializedProperty startRevProp;
		SerializedProperty startRotationAccelerationProp; 
		//SerializedProperty m_EmissionProp;

		void CheckStatic()
		{
			if (isShowEmitterSharp == null)
			{
				isShowEmitterSharp	= new SavedBool("ParticleRenderer.isShowEmitterSharp", false);
				isShowEmitter		= new SavedBool("ParticleRenderer.isShowEmitter", false);
				isShowRenderer		= new SavedBool("ParticleRenderer.isShowRenderer", false);
				isShowTexture		= new SavedBool("ParticleRenderer.isShowTexture", false);
			}
		}

		private void OnEnable()
		{
			rateOverTimeProp		= serializedObject.FindProperty("m_Emission.rateOverTime");
			rateOverDistanceProp	= serializedObject.FindProperty("m_Emission.rateOverDistance");
			intervalProp			= serializedObject.FindProperty("m_Emission.interval");

			IsRandomRotationProp			= serializedObject.FindProperty("m_Emission.IsRandomRotation");
			startRotationProp				= serializedObject.FindProperty("m_Emission.startRotation");
			startAccelerationProp			= serializedObject.FindProperty("m_Emission.startAcceleration");
			startRevProp					= serializedObject.FindProperty("m_Emission.startRev");
			startRotationAccelerationProp	= serializedObject.FindProperty("m_Emission.startRotationAcceleration");


			//m_EmissionProp			= serializedObject.FindProperty("m_Emission");
			//public EmissionParam m_Emission = new EmissionParam();
		}

		public void OnInspectorGUI(ParticleRenderer particle)
		{
			CheckStatic();

			particle.Duration = EditorGUILayout.FloatField("Duration:", particle.Duration);
			particle.DeltaTime = (ParticleRenderer.DeltaTimeMode)EditorGUILayout.EnumPopup("Delta Time Mode:", particle.DeltaTime);

			particle.CurPositionMode = (ParticleRenderer.PositionMode)EditorGUILayout.EnumPopup("Position Mode:", particle.CurPositionMode);

			particle.MaxParitcleCount = EditorGUILayout.IntField("Max Paritcle Count:", particle.MaxParitcleCount);

			isShowEmitterSharp.value = EditorGUILayout.Foldout(isShowEmitterSharp.value, "EmitterSharp");
			if (isShowEmitterSharp.value)
			{
				++EditorGUI.indentLevel;

				particle.EmitterParam.sharp = (EmitterSharpParam.SharpType)EditorGUILayout.EnumPopup("Emitter Sharp Type:", particle.EmitterParam.sharp);

				switch (particle.EmitterParam.sharp)
				{
					case EmitterSharpParam.SharpType.Cone:
						OnConeEmitterParamGUI(particle);
						break;
					case EmitterSharpParam.SharpType.Box:
						OnBoxEmitterParamGUI(particle);
						break;
				}
				--EditorGUI.indentLevel;
			}

			isShowEmitter.value = EditorGUILayout.Foldout(isShowEmitter.value, "Emission");
			if (isShowEmitter.value)
			{
				++EditorGUI.indentLevel;

				EditorGUILayout.BeginHorizontal();
				particle._ParticleLifeParam.x = EditorGUILayout.FloatField("Min Life:", particle._ParticleLifeParam.x);
				particle._ParticleLifeParam.y = EditorGUILayout.FloatField("Max Life:", particle._ParticleLifeParam.y);
				EditorGUILayout.EndHorizontal();

				EditorGUILayout.BeginHorizontal();
				particle._ParticleVelocityParam.x = EditorGUILayout.FloatField("Min Speed:", particle._ParticleVelocityParam.x);
				particle._ParticleVelocityParam.y = EditorGUILayout.FloatField("Max Speed:", particle._ParticleVelocityParam.y);
				EditorGUILayout.EndHorizontal();

				particle._ParticleVelocityParam.z = EditorGUILayout.FloatField("SpinSpeed:", particle._ParticleVelocityParam.z);
				particle._ParticleVelocityParam.w = EditorGUILayout.FloatField("SpinSpeedFromMoving:", particle._ParticleVelocityParam.w);
				particle._ParticleAccelerationParam.w = EditorGUILayout.FloatField("Spin Randomness:", particle._ParticleAccelerationParam.w);

				Vector3 Acceleration = new Vector3(particle._ParticleAccelerationParam.x, particle._ParticleAccelerationParam.y, particle._ParticleAccelerationParam.z);
				Acceleration = EditorGUILayout.Vector3Field("Acceleration:", Acceleration);
				particle._ParticleAccelerationParam.x = Acceleration.x;
				particle._ParticleAccelerationParam.y = Acceleration.y;
				particle._ParticleAccelerationParam.z = Acceleration.z;

				--EditorGUI.indentLevel;
			}

			isShowRenderer.value = EditorGUILayout.Foldout(isShowRenderer.value, "Renderer");
			if (isShowRenderer.value)
			{
				particle.isUpdateCompute = EditorGUILayout.Toggle("isUpdateCompute", particle.isUpdateCompute);

				particle.renderMode = (ParticleRenderer.RenderMode)EditorGUILayout.EnumPopup("Render Mode:", particle.renderMode);

				if (particle.renderMode == ParticleRenderer.RenderMode.Free )
				{
					particle.PerParticleMesh = (Mesh)EditorGUILayout.ObjectField("Particle Mesh:", particle.PerParticleMesh, typeof(Mesh), false);
				}

				particle.IsWarningUpStaticBatchOnAwake = EditorGUILayout.Toggle("Is Warning Up StaticBatch OnAwake", particle.IsWarningUpStaticBatchOnAwake);

				particle.StaticBatchRendering = EditorGUILayout.Toggle("Is Static Batch Rendering", particle.StaticBatchRendering);

				particle.StaticBatchCount = EditorGUILayout.IntField("StaticBatchCount", particle.StaticBatchCount);

				particle.material = (Material)EditorGUILayout.ObjectField("Material:", particle.material, typeof(Material), false);
			}

			isShowTexture.value = EditorGUILayout.Foldout(isShowTexture.value, "Texture");
			if (isShowTexture.value)
			{
				EditorGUILayout.LabelField("Position");
				EditorGUIExt.OnGUIDrawTexture(particle.PositionTexture);
				EditorGUIExt.OnGUIDrawTexture(particle.NextPositionTexture);
				EditorGUILayout.LabelField("Velocity");
				EditorGUIExt.OnGUIDrawTexture(particle.VelocityTexture);
				EditorGUIExt.OnGUIDrawTexture(particle.NextVelocityTexture);
				EditorGUILayout.LabelField("Spin");
				EditorGUIExt.OnGUIDrawTexture(particle.SpinTexture);
				EditorGUIExt.OnGUIDrawTexture(particle.NextSpinTexture);
			}
		}

		void OnConeEmitterParamGUI(ParticleRenderer particle)
		{
			particle._ParticleEmitterParam.x	= EditorGUILayout.FloatField("radius:",			particle._ParticleEmitterParam.x);
			particle._ParticleEmitterParam.y	= EditorGUILayout.Slider("radius thickness:",	particle._ParticleEmitterParam.y, 0.0f, 1.0f);
			particle._ParticleEmitterParam.z	= EditorGUILayout.Slider("angle:",				particle._ParticleEmitterParam.z, 0.0f, 90.0f);
			particle._ParticleEmitterParam.w	= EditorGUILayout.Slider("arc:",				particle._ParticleEmitterParam.w, 0.0f, 360.0f);
		}

		void OnBoxEmitterParamGUI(ParticleRenderer particle)
		{
			particle._ParticleEmitterParam.x = EditorGUILayout.FloatField("X Extend:", particle._ParticleEmitterParam.x);
			particle._ParticleEmitterParam.y = EditorGUILayout.FloatField("Y Extend:", particle._ParticleEmitterParam.y);;
			particle._ParticleEmitterParam.z = EditorGUILayout.FloatField("Z Extend:", particle._ParticleEmitterParam.z);
		}
#endif

		public override void OnInspectorGUI()
		{
			//base.OnInspectorGUI();
			serializedObject.Update();

			ParticleRenderer particle = target as ParticleRenderer;

			OnInspectorGUI(particle);

			serializedObject.ApplyModifiedProperties();
		}
	}
}