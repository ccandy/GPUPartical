using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

namespace Frameworks
{
	public static class EditorGUIExt
	{
		public static GUIContent[] TempContent(string[] texts)
		{
			GUIContent[] array = new GUIContent[texts.Length];
			for (int i = 0; i < texts.Length; i++)
			{
				array[i] = new GUIContent(texts[i]);
			}
			return array;
		}

		public static GUIContent TempContent(string texts)
		{
			return new GUIContent(texts);
		}

		public static int AspectSelectionGrid(int selected, Texture[] textures, int approxSize, GUIStyle style, GUIContent errorMessage, out bool doubleClick)
		{
			//IL_0069: Unknown result type (might be due to invalid IL or missing references)
			GUILayout.BeginVertical(new GUIStyle("box"), (GUILayoutOption[])(object)new GUILayoutOption[1]
			{
			GUILayout.MinHeight((float)approxSize)
			});
			int result = 0;
			doubleClick = false;
			if (textures.Length != 0)
			{
				int num = (int)(EditorGUIUtility.currentViewWidth - 150f) / approxSize;
				int num2 = (int)Mathf.Ceil((textures.Length + num - 1) / num);
				Rect aspectRect = GUILayoutUtility.GetAspectRect((float)num / (float)num2);
				Event current = Event.current;
				if ((int)current.type == 0 && current.clickCount == 2 && aspectRect.Contains(current.mousePosition))
				{
					doubleClick = true;
					current.Use();
				}
				result = GUI.SelectionGrid(aspectRect, Math.Min(selected, textures.Length - 1), textures, num, style);
			}
			else
			{
				GUILayout.Label(errorMessage, (GUILayoutOption[])(object)new GUILayoutOption[0]);
			}
			GUILayout.EndVertical();
			return result;
		}

		static Rect GetBrushAspectRect(int elementCount, int approxSize, int extraLineHeight, out int xCount)
		{
			xCount = (int)Mathf.Ceil((EditorGUIUtility.currentViewWidth - 20f) / (float)approxSize);
			int num = elementCount / xCount;
			if (elementCount % xCount != 0)
			{
				num++;
			}
			Rect aspectRect = GUILayoutUtility.GetAspectRect((float)xCount / (float)num);
			Rect rect = GUILayoutUtility.GetRect(10f, (float)(extraLineHeight * num));
			aspectRect.height += rect.height;
			return aspectRect;
		}

		public static int AspectSelectionGridImageAndText(int selected, GUIContent[] textures, int approxSize, GUIStyle style, string emptyString, out bool doubleClick)
		{
			//IL_004d: Unknown result type (might be due to invalid IL or missing references)
			EditorGUILayout.BeginVertical(EditorStyles.helpBox, GUILayout.MinHeight(10f));
			int result = 0;
			doubleClick = false;
			if (textures.Length != 0)
			{
				int xCount = 0;
				Rect brushAspectRect = GetBrushAspectRect(textures.Length, approxSize, 12, out xCount);
				Event current = Event.current;
				if (((int)current.type) == 0 && current.clickCount == 2 && brushAspectRect.Contains(current.mousePosition))
				{
					doubleClick = true;
					current.Use();
				}
				result = GUI.SelectionGrid(brushAspectRect, Math.Min(selected, textures.Length - 1), textures, xCount, style);
			}
			else
			{
				GUILayout.Label(emptyString, (GUILayoutOption[])(object)new GUILayoutOption[0]);
			}
			GUILayout.EndVertical();
			return result;
		}

		public static bool GPUGenTexture(Texture2D resultTexture, Material material)
		{
			if (resultTexture == null || material == null)
			{
				return false;
			}

			var pass0Target = RenderTexture.GetTemporary(resultTexture.width, resultTexture.height, 0, RenderTextureFormat.ARGB32);

			Graphics.SetRenderTarget(pass0Target);

			Mesh mesh = new Mesh();

			mesh.vertices = new Vector3[] { Vector3.zero, Vector3.right, Vector3.up, new Vector3(1, 1, 0) };
			mesh.uv = new Vector2[] { Vector2.zero, Vector2.right, Vector2.up, Vector2.one };
			mesh.SetIndices(new int[] { 0, 2, 1, 1, 2, 3 }, MeshTopology.Triangles, 0);
			mesh.RecalculateBounds();

			Graphics.DrawMeshNow(mesh, Matrix4x4.identity);

			resultTexture.ReadPixels(new Rect(0, 0, resultTexture.width, resultTexture.height), 0, 0);
			resultTexture.Apply();

			RenderTexture.ReleaseTemporary(pass0Target);

			UnityEngine.Object.DestroyImmediate(mesh);

			return true;
		}

		public static void OnGUIDrawTexture(Texture texture, float scaleSize = 1.0f)
		{
			if (texture == null)
				return;

			var rect = EditorGUILayout.GetControlRect(true, texture.height * scaleSize, EditorStyles.layerMaskField);
			rect.width = texture.width * scaleSize;
			EditorGUI.DrawPreviewTexture(rect, texture);
		}
	

		public static void OnFieldGUILayout( System.Object obj, string name)
		{
			OnFieldGUILayout(ref obj, obj.GetType(), name);
		}

		public static void OnFieldGUILayout(ref System.Object obj, Type type, string name)
		{
			if (type == typeof(bool))
			{
				obj = EditorGUILayout.Toggle(name, (bool)obj);
			}
			else if (type == typeof(int))
			{
				obj = EditorGUILayout.IntField(name, (int)obj);
			}
			else if (type == typeof(float))
			{
				obj = EditorGUILayout.FloatField(name, (float)obj);
			}
			else if (type == typeof(string))
			{
				if (obj == null)
					obj = "";
				obj = EditorGUILayout.TextField(name, (string)obj);
			}
			else if (type == typeof(Vector2))
			{
				obj = EditorGUILayout.Vector2Field(name, (Vector2)obj);
			}
			else if (type == typeof(Vector3))
			{
				obj = EditorGUILayout.Vector3Field(name, (Vector3)obj);
			}
			else if (type == typeof(Vector4))
			{
				obj = EditorGUILayout.Vector4Field(name, (Vector4)obj);
			}
			else if (type == typeof(Vector2Int))
			{
				obj = EditorGUILayout.Vector2IntField(name, (Vector2Int)obj);
			}
			else if (type == typeof(Vector3Int))
			{
				obj = EditorGUILayout.Vector3IntField(name, (Vector3Int)obj);
			}
			else if (type == typeof(AnimationCurve))
			{
				obj = EditorGUILayout.CurveField(name, (AnimationCurve)obj);
			}
			else if (type == typeof(Color))
			{
				var col = EditorGUILayout.ColorField(name, (Color)obj);
				obj = col;
			}
			else if (type.IsSubclassOf(typeof(UnityEngine.Object)))
			{
				obj = EditorGUILayout.ObjectField( name, (UnityEngine.Object)obj, type, true);
			}
			else
			{
				OnClassFieldGUILayout(ref obj, name);
			}
		}

		public static void OnClassFieldGUILayout(ref System.Object e, string name)
		{
			if (e == null)
				return;

			var classType = e.GetType();

			var fields = classType.GetFields();

			EditorGUILayout.LabelField(name);

			for (int i = 0; i < fields.Length; ++i)
			{
				var field = fields[i];

				var nonSerializeAttr = (System.NonSerializedAttribute)field.GetCustomAttributes(typeof(System.NonSerializedAttribute), true).SingleOrDefault();

				if (nonSerializeAttr != null)
					continue;

				var fieldObject = field.GetValue(e);

				if (field.FieldType == typeof(bool))
				{
					field.SetValue(e, EditorGUILayout.Toggle("\t" + field.Name, (bool)fieldObject));
				}
				else if (field.FieldType == typeof(int))
				{
					field.SetValue(e, EditorGUILayout.IntField("\t" + field.Name, (int)fieldObject));
				}
				else if (field.FieldType == typeof(float))
				{
					field.SetValue(e, EditorGUILayout.FloatField("\t" + field.Name, (float)fieldObject));
				}
				else if (field.FieldType == typeof(string))
				{
					field.SetValue(e, EditorGUILayout.TextField("\t" + field.Name, (string)fieldObject));
				}
				else if (field.FieldType == typeof(Vector2))
				{
					field.SetValue(e, EditorGUILayout.Vector2Field("\t" + field.Name, (Vector2)fieldObject));
				}
				else if (field.FieldType == typeof(Vector3))
				{
					field.SetValue(e, EditorGUILayout.Vector3Field("\t" + field.Name, (Vector3)fieldObject));
				}
				else if (field.FieldType == typeof(Vector4))
				{
					field.SetValue(e, EditorGUILayout.Vector4Field("\t" + field.Name, (Vector4)fieldObject));
				}
				else if (field.FieldType == typeof(Vector2Int))
				{
					field.SetValue(e, EditorGUILayout.Vector2IntField("\t" + field.Name, (Vector2Int)fieldObject));
				}
				else if (field.FieldType == typeof(Vector3Int))
				{
					field.SetValue(e, EditorGUILayout.Vector3IntField("\t" + field.Name, (Vector3Int)fieldObject));
				}
				else if (field.FieldType == typeof(AnimationCurve))
				{
					field.SetValue(e, EditorGUILayout.CurveField("\t" + field.Name, (AnimationCurve)fieldObject));
				}
				else if (field.FieldType.IsSubclassOf(typeof(UnityEngine.Object)))
				{
					field.SetValue(e, EditorGUILayout.ObjectField(name, (UnityEngine.Object)fieldObject, field.FieldType, true) );
				}
				else
				{
					System.Object obj =	field.GetValue(e);
					if (obj == null)
					{
						obj = Activator.CreateInstance(field.FieldType);
						field.SetValue(e, obj);
					}
					OnClassFieldGUILayout(ref obj, "\t" + field.Name);
				}
			}
		}


		private static readonly GUIStyle s_BlockSliderBG = "LODSliderRange";
		private static readonly GUIStyle s_TextCenteredStyle = new GUIStyle(EditorStyles.whiteMiniLabel)
		{
			alignment = TextAnchor.MiddleCenter
		};
		private const int kSliderbarTopMargin = 2;
		private const int kSliderbarHeight = 29;
		private const int kSliderbarBottomMargin = 2;
		private const int kPartitionHandleWidth = 2;
		private const int kPartitionHandleExtraHitAreaWidth = 2;
		private static readonly int s_BlockSliderId = "s_BlockSliderId".GetHashCode();

		public class DragCache
		{
			public int m_ActivePartition;          // the cascade partition that we are currently dragging/resizing
			public float m_NormalizedPartitionSize;  // the normalized size of the partition (0.0f < size < 1.0f)
			public Vector2 m_LastCachedMousePosition;  // mouse position the last time we registered a drag or mouse down.

			public DragCache(int activePartition, float normalizedPartitionSize, Vector2 currentMousePos)
			{
				m_ActivePartition = activePartition;
				m_NormalizedPartitionSize = normalizedPartitionSize;
				m_LastCachedMousePosition = currentMousePos;
			}
		};
		private static DragCache s_DragCache;

		private static readonly Color[] BlockSliderColors =
		{
			new Color(0.5f, 0.5f, 0.6f, 1.0f),
			new Color(0.5f, 0.6f, 0.5f, 1.0f),
			new Color(0.6f, 0.6f, 0.5f, 1.0f),
			new Color(0.6f, 0.5f, 0.5f, 1.0f),
		};

		public static void OnShadowCascadeSliderPercentGUILayout( ref int cascadeCount, ref Vector4 cascadesSplit, float distance = 1.0f, bool isShowValue = false)
		{
			if (cascadeCount == 0)
				return;

			if (cascadeCount > 4)
				cascadeCount = 4;

			EditorGUI.indentLevel--;
			EditorGUILayout.BeginHorizontal();
			GUILayout.Space(EditorGUI.indentLevel * 15f);
			// get the inspector width since we need it while drawing the partition rects.
			// Only way currently is to reserve the block in the layout using GetRect(), and then immediately drawing the empty box
			// to match the call to GetRect.
			// From this point on, we move to non-layout based code.

			var sliderRect = GUILayoutUtility.GetRect(GUIContent.none
					, s_BlockSliderBG
					, GUILayout.Height(kSliderbarTopMargin + kSliderbarHeight + kSliderbarBottomMargin)
					, GUILayout.ExpandWidth(true));
			GUI.Box(sliderRect, GUIContent.none);

			EditorGUILayout.EndHorizontal();

			float currentX = sliderRect.x;
			float BoxStartY = sliderRect.y + kSliderbarTopMargin;
			float blockSliderWidth = sliderRect.width - (cascadeCount * kPartitionHandleWidth);
			Color origTextColor = GUI.color;
			Color origBackgroundColor = GUI.backgroundColor;
			int colorIndex = -1;

			string blockText = "";
			// check for user input on any of the partition handles
			// this mechanism gets the current event in the queue... make sure that the mouse is over our control before consuming the event
			int sliderControlId = GUIUtility.GetControlID(s_BlockSliderId, FocusType.Passive);
			Event currentEvent = Event.current;
			int hotPartitionHandleIndex = -1; // the index of any partition handle that we are hovering over or dragging

			float sum = 0.0f;
			float currentPartition = 0.0f;

			float rightestValue = 0.0f;

			// draw each cascade partition
			for (int i = 0; i < cascadeCount; ++i)
			{
				if (i == cascadeCount - 1)
				{
					currentPartition = 1.0f - sum;
					rightestValue = currentPartition;
				}
				else
				{
					currentPartition = cascadesSplit[i];
				}


				colorIndex = (colorIndex + 1) % BlockSliderColors.Length;
				GUI.backgroundColor = BlockSliderColors[colorIndex];
				float boxLength = (blockSliderWidth * currentPartition);

				// main cascade box
				Rect partitionRect = new Rect(currentX, BoxStartY, boxLength, kSliderbarHeight);
				GUI.Box(partitionRect, GUIContent.none, s_BlockSliderBG);
				currentX += boxLength;

				// cascade box percentage text
				GUI.color = Color.white;
				Rect textRect = partitionRect;

				if (isShowValue)
				{
					var m = currentPartition * distance;
					blockText = $"{i + 1}\n{m:F1}m";
				}
				else
				{
					blockText = $"{i + 1}\n{currentPartition * 100.0f:F1}%";
				}

				GUI.Label(textRect, blockText, s_TextCenteredStyle);

				// no need to draw the partition handle for last box
				if (i == cascadeCount)
					break;

				// partition handle
				GUI.backgroundColor = Color.black;
				Rect handleRect = partitionRect;
				handleRect.x = currentX;
				handleRect.width = kPartitionHandleWidth;
				GUI.Box(handleRect, GUIContent.none, s_BlockSliderBG);
				// we want a thin handle visually (since wide black bar looks bad), but a slightly larger
				// hit area for easier manipulation
				Rect handleHitRect = handleRect;
				handleHitRect.xMin -= kPartitionHandleExtraHitAreaWidth;
				handleHitRect.xMax += kPartitionHandleExtraHitAreaWidth;
				if (handleHitRect.Contains(currentEvent.mousePosition))
					hotPartitionHandleIndex = i;

				// add regions to slider where the cursor changes to Resize-Horizontal
				if (s_DragCache == null)
				{
					EditorGUIUtility.AddCursorRect(handleHitRect, MouseCursor.ResizeHorizontal, sliderControlId);
				}

				currentX += kPartitionHandleWidth;
				sum += cascadesSplit[i];
			}

			GUI.color = origTextColor;
			GUI.backgroundColor = origBackgroundColor;

			EventType eventType = currentEvent.GetTypeForControl(sliderControlId);
			switch (eventType)
			{
				case EventType.MouseDown:
					if (hotPartitionHandleIndex >= 0)
					{
						s_DragCache = new DragCache(hotPartitionHandleIndex, cascadesSplit[hotPartitionHandleIndex], currentEvent.mousePosition);
						if (GUIUtility.hotControl == 0)
							GUIUtility.hotControl = sliderControlId;
						currentEvent.Use();
					}
					break;

				case EventType.MouseUp:
					// mouseUp event anywhere should release the hotcontrol (if it belongs to us), drags (if any)
					if (GUIUtility.hotControl == sliderControlId)
					{
						GUIUtility.hotControl = 0;
						currentEvent.Use();
					}
					s_DragCache = null;
					break;

				case EventType.MouseDrag:
					if (GUIUtility.hotControl != sliderControlId)
						break;

					// convert the mouse movement to normalized cascade width. Make sure that we are safe to apply the delta before using it.
					float delta = (currentEvent.mousePosition - s_DragCache.m_LastCachedMousePosition).x / blockSliderWidth;
					bool isLeftPartitionHappy = ((cascadesSplit[s_DragCache.m_ActivePartition] + delta) > 0.0f);
					bool isRightPartitionHappy = s_DragCache.m_ActivePartition + 1 >= cascadeCount-1 ? (rightestValue - delta) > 0.0f : ((cascadesSplit[s_DragCache.m_ActivePartition + 1] - delta) > 0.0f);
					if (isLeftPartitionHappy && isRightPartitionHappy)
					{
						s_DragCache.m_NormalizedPartitionSize += delta;
						cascadesSplit[s_DragCache.m_ActivePartition] = s_DragCache.m_NormalizedPartitionSize;
						if (s_DragCache.m_ActivePartition < cascadeCount)
							cascadesSplit[s_DragCache.m_ActivePartition + 1] -= delta;
						GUI.changed = true;
					}
					s_DragCache.m_LastCachedMousePosition = currentEvent.mousePosition;
					currentEvent.Use();
					break;
			}

		}

		public static void OnBlockSliderPercentGUILayout(ref float[] fValues, float distance = 1.0f, bool isShowValue = false)
		{
			if (fValues == null || fValues.Length == 0)
				return;

			EditorGUI.indentLevel--;
			EditorGUILayout.BeginHorizontal();
			GUILayout.Space(EditorGUI.indentLevel * 15f);
			// get the inspector width since we need it while drawing the partition rects.
			// Only way currently is to reserve the block in the layout using GetRect(), and then immediately drawing the empty box
			// to match the call to GetRect.
			// From this point on, we move to non-layout based code.

			var sliderRect = GUILayoutUtility.GetRect(GUIContent.none
					, s_BlockSliderBG
					, GUILayout.Height(kSliderbarTopMargin + kSliderbarHeight + kSliderbarBottomMargin)
					, GUILayout.ExpandWidth(true));
			GUI.Box(sliderRect, GUIContent.none);

			EditorGUILayout.EndHorizontal();

			float currentX = sliderRect.x;
			float BoxStartY = sliderRect.y + kSliderbarTopMargin;
			float blockSliderWidth = sliderRect.width - (fValues.Length * kPartitionHandleWidth);
			Color origTextColor = GUI.color;
			Color origBackgroundColor = GUI.backgroundColor;
			int colorIndex = -1;

			string blockText = "";
			// check for user input on any of the partition handles
			// this mechanism gets the current event in the queue... make sure that the mouse is over our control before consuming the event
			int sliderControlId = GUIUtility.GetControlID(s_BlockSliderId, FocusType.Passive);
			Event currentEvent = Event.current;
			int hotPartitionHandleIndex = -1; // the index of any partition handle that we are hovering over or dragging

			float sum = 0.0f;
			float currentPartition = 0.0f;

			float rightestValue = 0.0f;

			// draw each cascade partition
			for (int i = 0; i <= fValues.Length; ++i)
			{
				if (i == fValues.Length)
				{
					currentPartition = 1.0f - sum;
					rightestValue = currentPartition;
				}
				else
				{
					currentPartition = fValues[i];
				}


				colorIndex = (colorIndex + 1) % BlockSliderColors.Length;
				GUI.backgroundColor = BlockSliderColors[colorIndex];
				float boxLength = (blockSliderWidth * currentPartition);

				// main cascade box
				Rect partitionRect = new Rect(currentX, BoxStartY, boxLength, kSliderbarHeight);
				GUI.Box(partitionRect, GUIContent.none, s_BlockSliderBG);
				currentX += boxLength;

				// cascade box percentage text
				GUI.color = Color.white;
				Rect textRect = partitionRect;

				if (isShowValue)
				{
					var m = currentPartition * distance;
					blockText = $"{i + 1}\n{m:F1}m";
				}
				else
				{
					blockText = $"{i + 1}\n{currentPartition * 100.0f:F1}%";
				}

				GUI.Label(textRect, blockText, s_TextCenteredStyle);

				// no need to draw the partition handle for last box
				if (i == fValues.Length)
					break;

				// partition handle
				GUI.backgroundColor = Color.black;
				Rect handleRect = partitionRect;
				handleRect.x = currentX;
				handleRect.width = kPartitionHandleWidth;
				GUI.Box(handleRect, GUIContent.none, s_BlockSliderBG);
				// we want a thin handle visually (since wide black bar looks bad), but a slightly larger
				// hit area for easier manipulation
				Rect handleHitRect = handleRect;
				handleHitRect.xMin -= kPartitionHandleExtraHitAreaWidth;
				handleHitRect.xMax += kPartitionHandleExtraHitAreaWidth;
				if (handleHitRect.Contains(currentEvent.mousePosition))
					hotPartitionHandleIndex = i;

				// add regions to slider where the cursor changes to Resize-Horizontal
				if (s_DragCache == null)
				{
					EditorGUIUtility.AddCursorRect(handleHitRect, MouseCursor.ResizeHorizontal, sliderControlId);
				}

				currentX += kPartitionHandleWidth;
				sum += fValues[i];
			}

			GUI.color = origTextColor;
			GUI.backgroundColor = origBackgroundColor;

			EventType eventType = currentEvent.GetTypeForControl(sliderControlId);
			switch (eventType)
			{
				case EventType.MouseDown:
					if (hotPartitionHandleIndex >= 0)
					{
						s_DragCache = new DragCache(hotPartitionHandleIndex, fValues[hotPartitionHandleIndex], currentEvent.mousePosition);
						if (GUIUtility.hotControl == 0)
							GUIUtility.hotControl = sliderControlId;
						currentEvent.Use();
					}
					break;

				case EventType.MouseUp:
					// mouseUp event anywhere should release the hotcontrol (if it belongs to us), drags (if any)
					if (GUIUtility.hotControl == sliderControlId)
					{
						GUIUtility.hotControl = 0;
						currentEvent.Use();
					}
					s_DragCache = null;
					break;

				case EventType.MouseDrag:
					if (GUIUtility.hotControl != sliderControlId)
						break;

					// convert the mouse movement to normalized cascade width. Make sure that we are safe to apply the delta before using it.
					float delta = (currentEvent.mousePosition - s_DragCache.m_LastCachedMousePosition).x / blockSliderWidth;
					bool isLeftPartitionHappy = ((fValues[s_DragCache.m_ActivePartition] + delta) > 0.0f);
					bool isRightPartitionHappy = s_DragCache.m_ActivePartition + 1 >= fValues.Length ? (rightestValue - delta) > 0.0f : ((fValues[s_DragCache.m_ActivePartition + 1] - delta) > 0.0f);
					if (isLeftPartitionHappy && isRightPartitionHappy)
					{
						s_DragCache.m_NormalizedPartitionSize += delta;
						fValues[s_DragCache.m_ActivePartition] = s_DragCache.m_NormalizedPartitionSize;
						if (s_DragCache.m_ActivePartition < fValues.Length - 1)
							fValues[s_DragCache.m_ActivePartition + 1] -= delta;
						GUI.changed = true;
					}
					s_DragCache.m_LastCachedMousePosition = currentEvent.mousePosition;
					currentEvent.Use();
					break;
			}

		}

		public static void OnBlockSliderPercentGUILayout(ref List<float> fValues, float distance = 1.0f, bool isShowValue = false)
		{
			if (fValues == null || fValues.Count == 0)
				return;

			EditorGUI.indentLevel--;
			EditorGUILayout.BeginHorizontal();
			GUILayout.Space(EditorGUI.indentLevel * 15f);
			// get the inspector width since we need it while drawing the partition rects.
			// Only way currently is to reserve the block in the layout using GetRect(), and then immediately drawing the empty box
			// to match the call to GetRect.
			// From this point on, we move to non-layout based code.

			var sliderRect = GUILayoutUtility.GetRect(GUIContent.none
					, s_BlockSliderBG
					, GUILayout.Height(kSliderbarTopMargin + kSliderbarHeight + kSliderbarBottomMargin)
					, GUILayout.ExpandWidth(true));
			GUI.Box(sliderRect, GUIContent.none);

			EditorGUILayout.EndHorizontal();

			float currentX = sliderRect.x;
			float BoxStartY = sliderRect.y + kSliderbarTopMargin;
			float blockSliderWidth = sliderRect.width - (fValues.Count * kPartitionHandleWidth);
			Color origTextColor = GUI.color;
			Color origBackgroundColor = GUI.backgroundColor;
			int colorIndex = -1;

			string blockText = "";
			// check for user input on any of the partition handles
			// this mechanism gets the current event in the queue... make sure that the mouse is over our control before consuming the event
			int sliderControlId = GUIUtility.GetControlID(s_BlockSliderId, FocusType.Passive);
			Event currentEvent = Event.current;
			int hotPartitionHandleIndex = -1; // the index of any partition handle that we are hovering over or dragging

			float sum = 0.0f;
			float currentPartition = 0.0f;

			float rightestValue = 0.0f;

			// draw each cascade partition
			for (int i = 0; i <= fValues.Count; ++i)
			{
				if (i == fValues.Count)
				{
					currentPartition = 1.0f - sum;
					rightestValue = currentPartition;
				}
				else
				{
					currentPartition = fValues[i];
				}
				

				colorIndex = (colorIndex + 1) % BlockSliderColors.Length;
				GUI.backgroundColor = BlockSliderColors[colorIndex];
				float boxLength = (blockSliderWidth * currentPartition);

				// main cascade box
				Rect partitionRect = new Rect(currentX, BoxStartY, boxLength, kSliderbarHeight);
				GUI.Box(partitionRect, GUIContent.none, s_BlockSliderBG);
				currentX += boxLength;

				// cascade box percentage text
				GUI.color = Color.white;
				Rect textRect = partitionRect;

				if (isShowValue)
				{
					var m = currentPartition * distance;
					blockText = $"{i + 1}\n{m:F1}m";
				}
				else
				{
					blockText = $"{i + 1}\n{currentPartition * 100.0f:F1}%";
				}

				GUI.Label(textRect, blockText, s_TextCenteredStyle);

				// no need to draw the partition handle for last box
				if (i == fValues.Count)
					break;

				// partition handle
				GUI.backgroundColor = Color.black;
				Rect handleRect = partitionRect;
				handleRect.x = currentX;
				handleRect.width = kPartitionHandleWidth;
				GUI.Box(handleRect, GUIContent.none, s_BlockSliderBG);
				// we want a thin handle visually (since wide black bar looks bad), but a slightly larger
				// hit area for easier manipulation
				Rect handleHitRect = handleRect;
				handleHitRect.xMin -= kPartitionHandleExtraHitAreaWidth;
				handleHitRect.xMax += kPartitionHandleExtraHitAreaWidth;
				if (handleHitRect.Contains(currentEvent.mousePosition))
					hotPartitionHandleIndex = i;

				// add regions to slider where the cursor changes to Resize-Horizontal
				if (s_DragCache == null)
				{
					EditorGUIUtility.AddCursorRect(handleHitRect, MouseCursor.ResizeHorizontal, sliderControlId);
				}

				currentX += kPartitionHandleWidth;
				sum += fValues[i];
			}

			GUI.color = origTextColor;
			GUI.backgroundColor = origBackgroundColor;

			EventType eventType = currentEvent.GetTypeForControl(sliderControlId);
			switch (eventType)
			{
				case EventType.MouseDown:
					if (hotPartitionHandleIndex >= 0)
					{
						s_DragCache = new DragCache(hotPartitionHandleIndex, fValues[hotPartitionHandleIndex], currentEvent.mousePosition);
						if (GUIUtility.hotControl == 0)
							GUIUtility.hotControl = sliderControlId;
						currentEvent.Use();
					}
					break;

				case EventType.MouseUp:
					// mouseUp event anywhere should release the hotcontrol (if it belongs to us), drags (if any)
					if (GUIUtility.hotControl == sliderControlId)
					{
						GUIUtility.hotControl = 0;
						currentEvent.Use();
					}
					s_DragCache = null;
					break;

				case EventType.MouseDrag:
					if (GUIUtility.hotControl != sliderControlId)
						break;

					// convert the mouse movement to normalized cascade width. Make sure that we are safe to apply the delta before using it.
					float delta = (currentEvent.mousePosition - s_DragCache.m_LastCachedMousePosition).x / blockSliderWidth;
					bool isLeftPartitionHappy = ((fValues[s_DragCache.m_ActivePartition] + delta) > 0.0f);
					bool isRightPartitionHappy = s_DragCache.m_ActivePartition + 1 >= fValues.Count ? (rightestValue - delta) > 0.0f : ((fValues[s_DragCache.m_ActivePartition + 1] - delta) > 0.0f);
					if (isLeftPartitionHappy && isRightPartitionHappy)
					{
						s_DragCache.m_NormalizedPartitionSize += delta;
						fValues[s_DragCache.m_ActivePartition] = s_DragCache.m_NormalizedPartitionSize;
						if (s_DragCache.m_ActivePartition < fValues.Count - 1)
							fValues[s_DragCache.m_ActivePartition + 1] -= delta;
						GUI.changed = true;
					}
					s_DragCache.m_LastCachedMousePosition = currentEvent.mousePosition;
					currentEvent.Use();
					break;
			}
			
		}

		public static void OnBlockSliderGUILayout(ref List<float> fValues, List<string> title)
		{
			if (fValues == null || fValues.Count == 0)
				return;

			if (title.Count != fValues.Count)
				return;

			for (int i = 0; i < fValues.Count; ++i)
			{
				var posPerc = Mathf.Clamp(fValues[i], 0.01f, 1.0f) * 100f;
				var percValue = EditorGUILayout.Slider(EditorGUIUtility.TrTextContent(title[i]), (float)Math.Round(posPerc, 2), 0f, 100, null);
				fValues[i] = percValue / 100f;
			}
		}

		
	}
}

#endif