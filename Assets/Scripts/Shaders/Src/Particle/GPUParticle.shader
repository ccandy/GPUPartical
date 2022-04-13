Shader"GPUParticle/Particle/GPUDefault"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        [HDR]_Color("Base Color", Color) = (1,1,1,1)
        _MaskMap("Dissolve Mask Map", 2D) = "white" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0

        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }

    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "RenderPipeline" = "UniversalPipeline"            
        }

        Pass
        {
            Name "ParticleLit"
            Blend [_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma multi_compile_instancing

            #include "GPUParticlePass.hlsl"

            #pragma vertex      GPUParticleVert
            #pragma fragment    GPUParticleFrag

            ENDHLSL
        }
    }

    CustomEditor "Frameworks.RP.ParitcalShaderGUI"
}