using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace Frameworks.RP
{
	public class ParitcalShaderGUI : ShaderGUI
	{
		public enum BlendMode
		{
			Opaque,
			Cutout,
			Fade,		 // Old school alpha-blending mode, fresnel does not affect amount of transparency
			Transparent, // Physically plausible transparency mode, implemented as alpha pre-multiply
			Add,
		}

		public enum RenderFace
		{
			Front = 2,
			Back  = 1,
			Both  = 0
		}

		MaterialEditor m_MaterialEditor;

		MaterialProperty blendModeProp;
		MaterialProperty cullingProp;
		MaterialProperty alphaClipProp;
		MaterialProperty alphaCutoffProp;

		public virtual void FindProperties(MaterialProperty[] properties)
		{
			blendModeProp	= FindProperty("_Blend", properties, false);
			cullingProp		= FindProperty("_Cull", properties, false);
			alphaClipProp	= FindProperty("_AlphaClip", properties, false);
			alphaCutoffProp = FindProperty("_Cutoff", properties, false);
		}

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			base.OnGUI(materialEditor, properties);

			m_MaterialEditor = materialEditor;
			Material material = materialEditor.target as Material;

			FindProperties(properties);

			OnAlphaGUI(material);

			OnCullModeGUI(material);
		}

		public void OnAlphaGUI(Material material)
		{
			if (alphaCutoffProp != null)
			{
				EditorGUI.BeginChangeCheck();
				EditorGUI.showMixedValue = alphaCutoffProp.hasMixedValue;
				var alphaClipEnabled = EditorGUILayout.Toggle("Alpha Clip", alphaClipProp.floatValue == 1);
				if (EditorGUI.EndChangeCheck())
					alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;

				if (alphaClipProp.floatValue == 1)
					m_MaterialEditor.ShaderProperty(alphaCutoffProp, "Clip Threshold", 1);

				EditorGUI.showMixedValue = false;
			}

			if (blendModeProp != null)
			{
				DoPopup("Blend Mode", blendModeProp, Enum.GetNames(typeof(BlendMode)), m_MaterialEditor);
				BlendMode blendMode = (BlendMode)blendModeProp.floatValue;
				SetupMaterialWithBlendMode(material, blendMode);
			}
		}

		public void OnCullModeGUI(Material material)
		{
			EditorGUI.BeginChangeCheck();
			EditorGUI.showMixedValue = cullingProp.hasMixedValue;
			var culling = (RenderFace)cullingProp.floatValue;
			culling = (RenderFace)EditorGUILayout.EnumPopup("Cull Mode", culling);
			if (EditorGUI.EndChangeCheck())
			{
				m_MaterialEditor.RegisterPropertyChangeUndo("Cull Mode");
				cullingProp.floatValue = (float)culling;
				material.doubleSidedGI = (RenderFace)cullingProp.floatValue != RenderFace.Front;
			}

			EditorGUI.showMixedValue = false;
		}


		public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
		{
			switch (blendMode)
			{
				case BlendMode.Opaque:
					material.SetOverrideTag("RenderType", "Opaque");
					material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
					material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
					material.SetInt("_ZWrite", 1);
					material.DisableKeyword("_ALPHATEST_ON");
					material.DisableKeyword("_ALPHABLEND_ON");
					material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
					//material.renderQueue = -1;
					break;
				case BlendMode.Cutout:
					material.SetOverrideTag("RenderType", "TransparentCutout");
					material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
					material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
					material.SetInt("_ZWrite", 1);
					material.EnableKeyword("_ALPHATEST_ON");
					material.DisableKeyword("_ALPHABLEND_ON");
					material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
					//material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
					break;
				case BlendMode.Fade:
					material.SetOverrideTag("RenderType", "Transparent");
					material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
					material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
					material.SetInt("_ZWrite", 0);
					material.DisableKeyword("_ALPHATEST_ON");
					material.EnableKeyword("_ALPHABLEND_ON");
					material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
					//material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
					break;
				case BlendMode.Transparent:
					material.SetOverrideTag("RenderType", "Transparent");
					material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
					material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
					material.SetInt("_ZWrite", 0);
					material.DisableKeyword("_ALPHATEST_ON");
					material.DisableKeyword("_ALPHABLEND_ON");
					material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
					//material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
					break;
				case BlendMode.Add:
					material.SetOverrideTag("RenderType", "Transparent");
					material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
					material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
					material.SetInt("_ZWrite", 0);
					material.DisableKeyword("_ALPHATEST_ON");
					material.DisableKeyword("_ALPHABLEND_ON");
					material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
					//material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
					break;
			}
		}

		#region Helper Function
		public static void TwoFloatSingleLine(GUIContent title, MaterialProperty prop1, GUIContent prop1Label,
		   MaterialProperty prop2, GUIContent prop2Label, MaterialEditor materialEditor, float labelWidth = 30f)
		{
			EditorGUI.BeginChangeCheck();
			EditorGUI.showMixedValue = prop1.hasMixedValue || prop2.hasMixedValue;
			Rect rect = EditorGUILayout.GetControlRect();
			EditorGUI.PrefixLabel(rect, title);
			var indent = EditorGUI.indentLevel;
			var preLabelWidth = EditorGUIUtility.labelWidth;
			EditorGUI.indentLevel = 0;
			EditorGUIUtility.labelWidth = labelWidth;
			Rect propRect1 = new Rect(rect.x + preLabelWidth, rect.y,
				(rect.width - preLabelWidth) * 0.5f, EditorGUIUtility.singleLineHeight);
			var prop1val = EditorGUI.FloatField(propRect1, prop1Label, prop1.floatValue);

			Rect propRect2 = new Rect(propRect1.x + propRect1.width, rect.y,
				propRect1.width, EditorGUIUtility.singleLineHeight);
			var prop2val = EditorGUI.FloatField(propRect2, prop2Label, prop2.floatValue);

			EditorGUI.indentLevel = indent;
			EditorGUIUtility.labelWidth = preLabelWidth;

			if (EditorGUI.EndChangeCheck())
			{
				materialEditor.RegisterPropertyChangeUndo(title.text);
				prop1.floatValue = prop1val;
				prop2.floatValue = prop2val;
			}

			EditorGUI.showMixedValue = false;
		}

		public static void DoPopup(string label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
		{
			if (property == null)
				throw new ArgumentNullException("property");

			EditorGUI.showMixedValue = property.hasMixedValue;

			var mode = property.floatValue;
			EditorGUI.BeginChangeCheck();
			mode = EditorGUILayout.Popup(label, (int)mode, options);
			if (EditorGUI.EndChangeCheck())
			{
				materialEditor.RegisterPropertyChangeUndo(label);
				property.floatValue = mode;
			}

			EditorGUI.showMixedValue = false;
		}

		public new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties, bool propertyIsMandatory)
		{
			for (int index = 0; index < properties.Length; ++index)
			{
				if (properties[index] != null && properties[index].name == propertyName)
					return properties[index];
			}
			if (propertyIsMandatory)
				throw new ArgumentException("Could not find MaterialProperty: '" + propertyName + "', Num properties: " + (object)properties.Length);
			return null;
		}
		#endregion
	}
}
