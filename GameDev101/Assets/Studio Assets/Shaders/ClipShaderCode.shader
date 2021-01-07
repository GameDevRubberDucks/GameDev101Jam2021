// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/ClipShaderCode"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Colour", Color) = (1.0, 1.0, 1.0, 1.0)
        _NumSpheresActive("Num Active Spheres", Int) = 3
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull Off // Disable backface culling so you can see into the object when it is sliced

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float4 worldSpacePosition : TEXCOORD1; // Need the world space position so we can perform point-volume intersection checks in world space
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            
            // Sphere information
            #define MAX_SPHERES 3
            int _NumSpheresActive; // The number of light spheres actually in use - this does not have to match the maximum number, but it cannot really exceed it
            float3 _SphereCenters[MAX_SPHERES];
            float _SphereRadii[MAX_SPHERES];

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            int CheckAgainstSpheres(float3 _worldPos)
            {
                int sphereResult = 1000000;

                for (int i = 0; i < _NumSpheresActive && i < MAX_SPHERES; i++)
                {
                    float3 vecSphereCenterToPoint = _SphereCenters[i] - _worldPos;

                    float distance = length(vecSphereCenterToPoint);
                    distance -= _SphereRadii[i];

                    int distanceSign = sign(distance);

                    sphereResult = min(distanceSign, sphereResult);
                }

                return sphereResult;
            }

            fixed4 frag(v2f vInfo) : SV_Target
            {
                // MANUALLY HARD CODE THE FIRST SPHERES
                _SphereCenters[0] = float3(5.0f, 0.0f, 0.0f);
                _SphereRadii[0] = 5.0f;

                _SphereCenters[1] = float3(-5.0f, 0.0f, 0.0f);
                _SphereRadii[1] = 5.0f;

                _SphereCenters[2] = float3(0.0f, 5.0f, 0.0f);
                _SphereRadii[2] = 2.0f;

                int sphereResult = CheckAgainstSpheres(vInfo.worldSpacePosition.xyz);

                clip(-sphereResult);

                // sample the texture
                fixed4 col = tex2D(_MainTex, vInfo.uv) * _Color;
                return col;
        }
        ENDCG
    }
    }
}