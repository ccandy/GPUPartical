using System;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Frameworks.CRP.GPUParticle
{
	/*
	Development List:

	Emitter Sharp

	Emission
	
	Velocity Control

	Force Control

	Color Control
	 */
	public class ParticleRenderer : MonoBehaviour
	{
		#region Base Module
		public enum DeltaTimeMode
		{
			Scaled,
			Unscaled,
		}

		public enum RenderMode
		{
			BillBoard,
			Free,
		}

		public enum PositionMode
		{
			Local,
			World,
		}

		public float Duration;

		public float lifeTime = 5.0f;

		public int   MaxParitcleCount = 1000;

		public DeltaTimeMode	DeltaTime;

		public PositionMode		CurPositionMode;
		#endregion

		#region Emitter Sharp Module
		public EmitterSharpParam				EmitterParam = new EmitterSharpParam();

		#endregion

		#region Emitter Module
		public Vector4 _ParticlePositionOffset					= Vector4.zero;

		Vector4 _ParticleEmitterPosition						= new Vector4(0,0,0,1);
		Vector4 _ParticleEmitterRotator							= new Vector4(0,0,0,1);

		public Vector4 _ParticleBaseParam						= new Vector4(1000f, 0f, 0f, 0f); // Count,  passTime, pitchX, pitchY
		public Vector4 _ParticleEmitterParam					= new Vector4(1f,1f,20f,360f); // radius, radiusThickness, angleDegree, arcDegree
		public Vector4 _ParticleLifeParam						= Vector4.zero; // minLife, maxLife, deltaTime,
		public Vector4 _ParticleVelocityParam					= Vector4.zero; // MinSpeed, MaxSpeed, SpinSpeed, SpinSpeedFromMoving
		public Vector4 _ParticleAccelerationParam				= Vector4.zero; // Acceleration(xyz), SpinRandomness

		public Vector4[] _LifeColores							= new Vector4[2];
		public Vector4[] _LifeScales							= new Vector4[2];
		#endregion

		#region Render Module

		StaticBatchParticleMesh m_StaticBatchParticleMesh = new StaticBatchParticleMesh();

		public int StaticBatchCount = 1023;
		public bool IsWarningUpStaticBatchOnAwake = true;
		public bool StaticBatchRendering = true;

		public static class ShaderConstant
		{
			public static int _ParticleEmitterSharp		 = Shader.PropertyToID("_ParticleEmitterSharp");
			public static int _ParticlePositionOffset	 = Shader.PropertyToID("_ParticlePositionOffset");

			public static int _ParticleEmitterPosition	 = Shader.PropertyToID("_ParticleEmitterPosition");
			public static int _ParticleEmitterRotator	 = Shader.PropertyToID("_ParticleEmitterRotator");

			public static int _InstanceOffset			 = Shader.PropertyToID("_InstanceOffset");
			public static int _MeshVerticesCount		 = Shader.PropertyToID("_MeshVerticesCount");
			public static int _MeshCountPerGroup		 = Shader.PropertyToID("_MeshCountPerGroup");

			public static int _ParticleBaseParam		 = Shader.PropertyToID("_ParticleBaseParam");           // Count,  passTime, pitchX, pitchY
			public static int _ParticleEmitterParam		 = Shader.PropertyToID("_ParticleEmitterParam");        // radius, radiusThickness, angleDegree, arcDegree
			public static int _ParticleLifeParam		 = Shader.PropertyToID("_ParticleLifeParam");           // minLife, maxLife, deltaTime,
			public static int _ParticleVelocityParam	 = Shader.PropertyToID("_ParticleVelocityParam");		// MinSpeed, MaxSpeed, SpinSpeed, SpinSpeedFromMoving
			public static int _ParticleAccelerationParam = Shader.PropertyToID("_ParticleAccelerationParam");	// Acceleration(xyz), SpinRandomness

			public static int _InPositionTexture		 = Shader.PropertyToID("_InPositionTexture"); // position(xyz), curLife( 0 : the end of life)
			public static int _InVelocityTexture		 = Shader.PropertyToID("_InVelocityTexture"); // velocity(xyz), totalLife
			public static int _InSpinTexture			 = Shader.PropertyToID("_InSpinTexture");
			
			public static int _OutPositionTexture		 = Shader.PropertyToID("_OutPositionTexture");
			public static int _OutVelocityTexture		 = Shader.PropertyToID("_OutVelocityTexture");
			public static int _OutSpinTexture			 = Shader.PropertyToID("_OutSpinTexture");

			public static int _LifeColores				 = Shader.PropertyToID("_LifeColores");
			public static int _LifeScales				 = Shader.PropertyToID("_LifeScales");
		}

		public Mesh PerParticleMesh;

		public Material material;

		public RenderMode renderMode = RenderMode.BillBoard;

		bool isFirstFrame = true;

		Vector2Int m_TextureResolution = Vector2Int.zero;

		public RenderTexture PositionTexture
		{
			get => m_PositionTexture[curTextureIndex];
		}

		public RenderTexture VelocityTexture
		{
			get => m_VelocitynTexture[curTextureIndex];
		}

		public RenderTexture SpinTexture
		{
			get => m_SpinTexture[curTextureIndex];
		}

		public RenderTexture NextPositionTexture
		{
			get => m_PositionTexture[(curTextureIndex + 1) % 2];
		}

		public RenderTexture NextVelocityTexture
		{
			get => m_VelocitynTexture[(curTextureIndex + 1) % 2];
		}

		public RenderTexture NextSpinTexture
		{
			get => m_SpinTexture[(curTextureIndex + 1) % 2];
		}

		RenderTexture[]		m_PositionTexture		= new RenderTexture[2];
		RenderTexture[]		m_VelocitynTexture		= new RenderTexture[2];
		RenderTexture[]		m_SpinTexture			= new RenderTexture[2];

		RenderTargetSetup[] m_RenderTargetSetups	= new RenderTargetSetup[2];

		int curTextureIndex = 0;

		MaterialPropertyBlock m_MaterialPropertyBlock;

		Matrix4x4[] m_RenderingMatrix;

		#endregion

		//[SerializeField]
		public ComputeShader GPUParticleCompute;
		int _KernelInitParticle;
		int _KernelUpdateBillboardParticle;
		int _KernelUpdateParticle;

		public bool IsPlaying = false;

		public float PassTime = 0.0f;

		int CanEmitterMaxCount = 0;

		float lastEmitterPassTime = 0.0f;

		float GetTimeDelta()
		{
#if UNITY_EDITOR
			if (Application.isPlaying)
			{
				switch (DeltaTime)
				{
					case DeltaTimeMode.Scaled:
						return Time.deltaTime;
					case DeltaTimeMode.Unscaled:
						return Time.unscaledDeltaTime;
				}
			}
			else
			{
				return Time.captureDeltaTime;
			}
#else
			switch (DeltaTime)
			{
				case DeltaTimeMode.Scaled:
					return Time.deltaTime;
				case DeltaTimeMode.Unscaled:
					return Time.unscaledDeltaTime;
			}
#endif
			return 0.0f;
		}
		public bool isUpdateCompute = true;
		void OnComputeUpdateTexture(bool isInitParticle)
		{
			if (!isUpdateCompute)
				return;

			int nextIndex = (curTextureIndex + 1) % 2;

			GPUParticleCompute.SetInt(ShaderConstant._ParticleEmitterSharp,			(int)EmitterParam.sharp);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleBaseParam,			_ParticleBaseParam);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleEmitterParam,		_ParticleEmitterParam);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleLifeParam,			_ParticleLifeParam);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleVelocityParam,		_ParticleVelocityParam);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleAccelerationParam, _ParticleAccelerationParam);

			GPUParticleCompute.SetVector(ShaderConstant._ParticleEmitterPosition,	_ParticleEmitterPosition);
			GPUParticleCompute.SetVector(ShaderConstant._ParticleEmitterRotator,	_ParticleEmitterRotator);

#if SHADER_API_SWITCH //PLATFORM_SWITCH
			int dispatchCount = (int)_ParticleBaseParam.x / 32 + ((int)_ParticleBaseParam.x % 32 != 0 ? 1 : 0);
#else
			int dispatchCount = (int)_ParticleBaseParam.x / 64 + ((int)_ParticleBaseParam.x % 64 != 0 ? 1 : 0);
#endif

			if (dispatchCount == 0)
				return;

			if (isInitParticle)
			{
				GPUParticleCompute.SetTexture(_KernelInitParticle, ShaderConstant._OutPositionTexture,  m_PositionTexture[curTextureIndex]);
				GPUParticleCompute.SetTexture(_KernelInitParticle, ShaderConstant._OutVelocityTexture,  m_VelocitynTexture[curTextureIndex]);
				GPUParticleCompute.SetTexture(_KernelInitParticle, ShaderConstant._OutSpinTexture,		m_SpinTexture[curTextureIndex]);

				GPUParticleCompute.Dispatch(_KernelInitParticle, dispatchCount, 1, 1);
			}

			switch (renderMode)
			{
				case RenderMode.BillBoard:
					{
						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._InPositionTexture, m_PositionTexture[curTextureIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._InVelocityTexture, m_VelocitynTexture[curTextureIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._InSpinTexture,	 m_SpinTexture[curTextureIndex]);

						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._OutPositionTexture, m_PositionTexture[nextIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._OutVelocityTexture, m_VelocitynTexture[nextIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateBillboardParticle, ShaderConstant._OutSpinTexture,	  m_SpinTexture[nextIndex]);

						GPUParticleCompute.Dispatch(_KernelUpdateBillboardParticle, dispatchCount, 1, 1);
					}
					break;
				case RenderMode.Free:
					{
						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._InPositionTexture, m_PositionTexture[curTextureIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._InVelocityTexture, m_VelocitynTexture[curTextureIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._InSpinTexture,		m_SpinTexture[curTextureIndex]);

						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._OutPositionTexture, m_PositionTexture[nextIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._OutVelocityTexture, m_VelocitynTexture[nextIndex]);
						GPUParticleCompute.SetTexture(_KernelUpdateParticle, ShaderConstant._OutSpinTexture,	 m_SpinTexture[nextIndex]);

						GPUParticleCompute.Dispatch(_KernelUpdateParticle, dispatchCount, 1, 1);
					}
					break;
			}
			
			curTextureIndex = nextIndex;
		}

		void OnUpdateTexture(bool isInitParticle)
		{
			int nextIndex = (curTextureIndex + 1) % 2;
			OnEmitterMaterialPropetiesUpload();


			curTextureIndex = nextIndex;
		}

		void OnEmitterMaterialPropetiesUpload()
		{
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleEmitterPosition,	 _ParticleEmitterPosition);
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleEmitterRotator,	 _ParticleEmitterRotator);

			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleBaseParam,		 _ParticleBaseParam);
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleEmitterParam,		 _ParticleEmitterParam);
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleLifeParam,		 _ParticleLifeParam);
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleVelocityParam,	 _ParticleVelocityParam);
			m_MaterialPropertyBlock.SetVector(ShaderConstant._ParticleAccelerationParam, _ParticleAccelerationParam);

			m_MaterialPropertyBlock.SetTexture(ShaderConstant._InPositionTexture,		 m_PositionTexture[curTextureIndex]);
			m_MaterialPropertyBlock.SetTexture(ShaderConstant._InVelocityTexture,		 m_VelocitynTexture[curTextureIndex]);
			m_MaterialPropertyBlock.SetTexture(ShaderConstant._InSpinTexture,			 m_SpinTexture[curTextureIndex]);	
		}

		void ClearTexture()
		{
			for (int i = 0; i < 2; ++i)
			{
				if (m_PositionTexture[i] != null)
				{
					RenderTexture.ReleaseTemporary(m_PositionTexture[i]);
					//Destroy(m_PositionTexture[i]);
				}

				if (m_VelocitynTexture[i] != null)
				{
					RenderTexture.ReleaseTemporary(m_VelocitynTexture[i]);
					//Destroy(m_VelocitynTexture[i]);
				}

				if (m_SpinTexture[i] != null)
				{
					RenderTexture.ReleaseTemporary(m_SpinTexture[i]);
					//Destroy(m_SpinTexture[i]);
				}
			}
			m_TextureResolution = Vector2Int.zero;
		}

		bool CheckAndResetRenderTexture()
		{
			bool isNeedRenew = MaxParitcleCount > m_TextureResolution.x * m_TextureResolution.y;

			if (isNeedRenew)
			{
				ClearTexture();

				Vector2Int newResolution = new Vector2Int();

				newResolution.x = Mathf.NextPowerOfTwo( Mathf.CeilToInt(Mathf.Sqrt(MaxParitcleCount)) );
				newResolution.y = Mathf.NextPowerOfTwo( MaxParitcleCount / newResolution.x + ((newResolution.x % newResolution.x != 0)?1:0));

				m_TextureResolution = newResolution;

				RenderTextureDescriptor desc = new RenderTextureDescriptor(newResolution.x, newResolution.y, RenderTextureFormat.ARGBFloat, 0, 0);
				desc.enableRandomWrite = true;
				desc.autoGenerateMips = false;

				for (int i = 0; i < 2; ++i)
				{
					m_PositionTexture[i]	= RenderTexture.GetTemporary(desc);
					m_VelocitynTexture[i]	= RenderTexture.GetTemporary(desc);
					m_SpinTexture[i]		= RenderTexture.GetTemporary(desc);

					//m_PositionTexture[i]	= new RenderTexture(desc);
					//m_VelocitynTexture[i]	= new RenderTexture(desc);
					//m_SpinTexture[i]		= new RenderTexture(desc);

					m_PositionTexture[i].filterMode  = FilterMode.Point;
					m_VelocitynTexture[i].filterMode = FilterMode.Point;
					m_SpinTexture[i].filterMode		 = FilterMode.Point;

					var setup = new RenderTargetSetup();

					setup.color = new RenderBuffer[] 
									{
										m_PositionTexture[i].colorBuffer,
										m_VelocitynTexture[i].colorBuffer,
										m_SpinTexture[i].colorBuffer,
									};

					setup.colorLoad = new RenderBufferLoadAction[]
									{
										RenderBufferLoadAction.DontCare,
										RenderBufferLoadAction.DontCare,
										RenderBufferLoadAction.DontCare,
									};

					setup.colorStore = new RenderBufferStoreAction[]
									{
										RenderBufferStoreAction.Store,
										RenderBufferStoreAction.Store,
										RenderBufferStoreAction.Store,
									};

					m_RenderTargetSetups[i] = setup;
				}

				isFirstFrame = true;
			}

			return isNeedRenew;
		}

		Mesh GetRenderingMesh()
		{
			var renderingMesh = PerParticleMesh;

			if (renderingMesh == null)
			{
				//renderingMesh = RenderBaseFunction.particleMeshQuad;
				renderingMesh = GeneratePartichMeshQuad();
			}

			return renderingMesh;
		}

		void OnInstancingRenderUpdate(float deltaTime)
		{
			var renderingMesh = GetRenderingMesh();

			OnEmitterMaterialPropetiesUpload();

			int renderIndex = 0;

			m_MaterialPropertyBlock.SetInt(ShaderConstant._MeshVerticesCount, (int)renderingMesh.vertexCount);
			m_MaterialPropertyBlock.SetInt(ShaderConstant._MeshCountPerGroup, 1);

			for (; renderIndex < _ParticleBaseParam.x; )
			{
				int renderCount = Mathf.Min( 1023, (int)(_ParticleBaseParam.x - renderIndex));

				m_MaterialPropertyBlock.SetInt(ShaderConstant._InstanceOffset, renderIndex);

				Graphics.DrawMeshInstanced(renderingMesh, 0, material, m_RenderingMatrix, renderCount, m_MaterialPropertyBlock);

				renderIndex += renderCount;
			}

		}

		public Mesh testMesh;

		void OnStaticBatchRenderUpdate(float deltaTime)
		{
			m_StaticBatchParticleMesh.BatchCount = StaticBatchCount;

			var renderingMesh = m_StaticBatchParticleMesh.BatchMesh;

			testMesh = renderingMesh;

			OnEmitterMaterialPropetiesUpload();

			int renderIndex = 0;

			int renderingCount = (int)_ParticleBaseParam.x;

			m_MaterialPropertyBlock.SetInt(ShaderConstant._MeshVerticesCount, (int)m_StaticBatchParticleMesh.bindMesh.vertexCount);
			m_MaterialPropertyBlock.SetInt(ShaderConstant._MeshCountPerGroup, m_StaticBatchParticleMesh.BatchCount);

			for (; renderIndex < renderingCount;)
			{
				int renderCount = renderingCount - renderIndex;

				int batchRenderCount = renderCount / m_StaticBatchParticleMesh.BatchCount;
				if (renderCount % m_StaticBatchParticleMesh.BatchCount != 0)
					++batchRenderCount;

				if (batchRenderCount > 1023)
				{
					batchRenderCount = 1023;
					renderCount = batchRenderCount * m_StaticBatchParticleMesh.BatchCount;
				}

				m_MaterialPropertyBlock.SetInt(ShaderConstant._InstanceOffset, renderIndex);

				Graphics.DrawMeshInstanced(renderingMesh, 0, material, m_RenderingMatrix, batchRenderCount, m_MaterialPropertyBlock);

				renderIndex += renderCount;
			}
		}

		void Awake()
		{
			m_MaterialPropertyBlock = new MaterialPropertyBlock();

			if (IsWarningUpStaticBatchOnAwake)
			{
				DoWarningUpStaticMesh();
			}
		}

		public void DoWarningUpStaticMesh(bool isForce = false)
		{
			var renderingMesh = GetRenderingMesh();
			if (m_StaticBatchParticleMesh == null)
			{
				m_StaticBatchParticleMesh = new StaticBatchParticleMesh();
			}
			m_StaticBatchParticleMesh.bindMesh = renderingMesh;
			m_StaticBatchParticleMesh.BatchCount = StaticBatchCount;
			m_StaticBatchParticleMesh.DoBatch(isForce);
		}

		bool isEnableFrame = false;

		void OnEnable()
		{
			isEnableFrame = true;
			if (m_MaterialPropertyBlock == null)
			{
				m_MaterialPropertyBlock = new MaterialPropertyBlock();
			}

			if (material != null)
			{
				material.enableInstancing = true;
			}

			if (m_RenderingMatrix == null)
			{
				m_RenderingMatrix = new Matrix4x4[1023];
				for (int i = 0; i < 1023; ++i)
				{
					m_RenderingMatrix[i] = transform.localToWorldMatrix;//  Matrix4x4.identity;
				}
			}

			if (GPUParticleCompute != null)
			{
				_KernelInitParticle				= GPUParticleCompute.FindKernel("InitParticle");
				_KernelUpdateBillboardParticle	= GPUParticleCompute.FindKernel("UpdateBillboardParticle");
				_KernelUpdateParticle			= GPUParticleCompute.FindKernel("UpdateParticle");
            }
            else
            {
				Debug.LogError("Need a cs to run");
            }

			CheckAndResetRenderTexture();
			//OnComputeUpdateTexture(true);
		}

		void OnDisable()
		{
			ClearTexture();	
		}

		Mesh GeneratePartichMeshQuad()
        {
			Mesh quadMesh = new Mesh { name = "Quad Mesh" };

			float topV = 1.0f;
			float bottomV = 0.0f;

			quadMesh.SetVertices(new List<Vector3>
				{
					new Vector3(-0.5f, -0.5f, 0.0f),
					new Vector3(-0.5f,  0.5f, 0.0f),
					new Vector3(0.5f, -0.5f, 0.0f),
					new Vector3(0.5f,  0.5f, 0.0f)
				});


			quadMesh.SetUVs(0, new List<Vector2>
				{
					new Vector2(0.0f, bottomV),
					new Vector2(0.0f, topV),
					new Vector2(1.0f, bottomV),
					new Vector2(1.0f, topV)
				});
			quadMesh.SetIndices(new[] { 0, 1, 2, 2, 1, 3 }, MeshTopology.Triangles, 0, false);
			quadMesh.UploadMeshData(false);
			quadMesh.bounds = new Bounds(Vector3.zero, Vector3.one * 9999);

			return quadMesh;
		}

		void Update()
		{
			CheckAndResetRenderTexture();

			float delta = 0.0f;
			if (IsPlaying)
			{
				delta = GetTimeDelta();
				PassTime += delta;
				_ParticleBaseParam.x = MaxParitcleCount;
				_ParticleBaseParam.y = Mathf.Repeat( PassTime, 30) + 2323;
				_ParticleBaseParam.z = m_TextureResolution.x;
				_ParticleBaseParam.w = m_TextureResolution.y;
				_ParticleLifeParam.z = delta;

				_ParticleEmitterPosition = transform.position;
				_ParticleEmitterRotator.x = transform.rotation.x;
				_ParticleEmitterRotator.y = transform.rotation.y;
				_ParticleEmitterRotator.z = transform.rotation.z;
				_ParticleEmitterRotator.w = transform.rotation.w;
			}

			OnComputeUpdateTexture(!isEnableFrame&&isFirstFrame);
			if (!isEnableFrame)
				isFirstFrame = false;

			if (StaticBatchRendering)
				OnStaticBatchRenderUpdate(delta);
			else
				OnInstancingRenderUpdate(delta);

			isEnableFrame = false;
		}


	}
}
