using System;
using System.Collections.Generic;
using UnityEngine;

namespace Frameworks.CRP.GPUParticle
{
	public class StaticBatchParticleMesh
	{
		const int maxBatchParticleVertices = 40000;

		const int maxBatchParticleIndices  = 60000;

		public Mesh bindMesh
		{
			get => m_bindMesh;
			set
			{
				if (m_bindMesh == value)
					return;

				m_bindMesh = value;
				isNeedDoBatch = true;
			}
		}

		Mesh m_bindMesh = null;

		public int BatchCount
		{
			get => m_BatchCount;
			set
			{
				if (m_bindMesh != null)
				{
					int maxCount = (int)(maxBatchParticleVertices / m_bindMesh.vertexCount );

					maxCount = Mathf.Min((int)(maxBatchParticleIndices / m_bindMesh.GetIndexCount(0)), maxCount);

					maxCount = Mathf.Max(1, maxCount);

					value = Mathf.Min(maxCount, value);
				}

				if (m_BatchCount == value)
					return;

				m_BatchCount = value;
				isNeedDoBatch = true;
			}
		}

		int m_BatchCount = 0;

		public Mesh BatchMesh
		{
			get
			{
				DoBatch(false);
				return m_BatchMesh;
			}
		}

		Mesh m_BatchMesh = null;

		public bool isNeedDoBatch = true;

		public void DoBatch(bool isForce = false)
		{
			if (!isNeedDoBatch && !isForce)
				return;

			isNeedDoBatch = false;

			if (m_BatchMesh == null)
			{
				m_BatchMesh = new Mesh();
			}

			m_BatchMesh.Clear();

			if (bindMesh == null)
			{
				return;
			}

			var bindIndices = bindMesh.GetIndices(0);

			int singleMeshVerticesLen =  bindMesh.vertexCount;
			int singleMeshIndicesLen = bindIndices.Length;

			int maxBatchCount = (int)(maxBatchParticleVertices / m_bindMesh.vertexCount);

			maxBatchCount = Mathf.Min((int)(maxBatchParticleIndices / m_bindMesh.GetIndexCount(0)), maxBatchCount);

			m_BatchCount = Mathf.Min(m_BatchCount, maxBatchCount);

			m_BatchCount = Mathf.Max(m_BatchCount, 1);


			int[] batchIndices = new int[m_BatchCount * singleMeshIndicesLen];

			for (int i = 0; i < batchIndices.Length; i += singleMeshIndicesLen)
			{
				Array.Copy(bindIndices, 0, batchIndices, i, singleMeshIndicesLen);
				for (int j = 0; j < bindIndices.Length; ++j)
				{
					bindIndices[j] += singleMeshVerticesLen;
				}
			}

			var vertices = bindMesh.vertices;
			Vector3[] batchVertices = new Vector3[m_BatchCount * singleMeshVerticesLen];
			for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
			{
				Array.Copy(vertices, 0, batchVertices, i, singleMeshVerticesLen);
			}
			m_BatchMesh.vertices = batchVertices;

			var normals = bindMesh.normals;
			if (normals.Length > 0)
			{
				Vector3[] batchNormals = new Vector3[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(normals, 0, batchNormals, i, singleMeshVerticesLen);
				}
				m_BatchMesh.normals = batchNormals;
			}

			var tangents = bindMesh.tangents;
			if (tangents.Length > 0)
			{
				Vector4[] batchTangents = new Vector4[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(tangents, 0, batchTangents, i, singleMeshVerticesLen);
				}
				m_BatchMesh.tangents = batchTangents;
			}

			var uv = bindMesh.uv;
			Vector2[] batchUV = null;
			if (uv.Length > 0)
			{
				if (batchUV == null)
					batchUV = new Vector2[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(uv, 0, batchUV, i, singleMeshVerticesLen);
				}
				m_BatchMesh.uv = batchUV;
			}

			uv = bindMesh.uv2;
			if (uv.Length > 0)
			{
				if (batchUV == null)
					batchUV = new Vector2[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(uv, 0, batchUV, i, singleMeshVerticesLen);
				}
				m_BatchMesh.uv2 = batchUV;
			}

			uv = bindMesh.uv3;
			if (uv.Length > 0)
			{
				if(batchUV == null)
					batchUV = new Vector2[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(uv, 0, batchUV, i, singleMeshVerticesLen);
				}
				m_BatchMesh.uv3 = batchUV;
			}

			uv = bindMesh.uv4;
			if (uv.Length > 0)
			{
				if (batchUV == null)
					batchUV = new Vector2[m_BatchCount * singleMeshVerticesLen];
				for (int i = 0; i < batchVertices.Length; i += singleMeshVerticesLen)
				{
					Array.Copy(uv, 0, batchUV, i, singleMeshVerticesLen);
				}
				m_BatchMesh.uv4 = batchUV;
			}


			m_BatchMesh.SetIndices(batchIndices, MeshTopology.Triangles, 0);

			m_BatchMesh.bounds = new Bounds(Vector3.zero, new Vector3(9999, 9999, 9999));
		}
	}
}
