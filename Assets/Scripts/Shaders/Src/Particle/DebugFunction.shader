Shader "CustomRenderPipeline/Particle/DebugFunction"
{
    Properties
    {
        _Rotator("Rotator:", Vector) = (0,0,0,1)
    }

    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector"="True"
            "RenderPipeline" = "CustomPipeline" 
        }

        Pass
        {
            Name "ParticleLit"
            Blend One Zero
            

            Tags{"LightMode" = "CustomForward"}

            HLSLPROGRAM

            #include "../../Include/BaseDefine/ConstDefine.hlsl"
            #include "../../Include/BaseDefine/CommonDefine.hlsl"
            #include "../../Include/BaseDefine/SpaceFunction.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
                float4 color  : COLOR0;
                float4 uv0    : TEXCOORD0;
                float4 uv1    : TEXCOORD1;

	            UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 posMVP : SV_POSITION;
            };

            float4 _Rotator;

            Varyings TestFuncVert(Attributes v, uint vIndex : SV_VertexID)
            {
                float4 rotator = Euler(_Rotator.xyz * M_DEG_TO_RAD);
    
                v.vertex.xyz = QuaternionMulVector(rotator, v.vertex.xyz);
    
                Varyings o = (Varyings) 0;
                float4 posWorld = mul(UNITY_MATRIX_M, v.vertex); 

                o.posMVP          = mul(UNITY_MATRIX_VP, posWorld);
                return o;
            }

            float4 TestFuncFrag() : SV_Target
            {
                return (0,1,0,1);
            }

            #pragma vertex      TestFuncVert
            #pragma fragment    TestFuncFrag

            ENDHLSL
        }
    }
}