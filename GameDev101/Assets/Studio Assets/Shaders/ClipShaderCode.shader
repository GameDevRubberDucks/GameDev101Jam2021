// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/ClipShaderCode"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Colour", Color) = (1.0, 1.0, 1.0, 1.0)
        [HideInInspector] _NumSpheresActive("Num Active Spheres", Int) = 3
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
            #define MAX_SPHERES 10
            int _NumSpheresActive; // The number of light spheres actually in use - this does not have to match the maximum number, but it cannot really exceed it
            float4 _SphereCenters[MAX_SPHERES]; // The x,y,z are valid. The w values are just 0's
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
                // The result will either be a -1 or 1 in the end
                // -1 means that the fragment is within a sphere and should be rendered, 1 means it is outside
                // Need to start with this high number so the min() function works correctly
                int sphereResult = 1000000;

                // Loop through all of the spheres and see if the fragment is within one or more of the spheres
                for (int i = 0; i < _NumSpheresActive && i < MAX_SPHERES; i++)
                {
                    // Calculate the distance from the fragment to the sphere
                    float3 vecSphereCenterToPoint = _SphereCenters[i].xyz - _worldPos;
                    float distance = length(vecSphereCenterToPoint);
                    distance -= _SphereRadii[i];

                    // If the distance is negative, the fragment is INSIDE the sphere, positive means OUTSIDE
                    int distanceSign = sign(distance);

                    // Use min to ensure that if it is in at least one sphere, the result is -1
                    sphereResult = min(distanceSign, sphereResult);
                }

                return sphereResult;
            }

            fixed4 frag(v2f vInfo) : SV_Target
            {
                // Check to see if the fragment falls into any of the spheres
                // If it does, this value is -1 and should be rendered
                int sphereResult = CheckAgainstSpheres(vInfo.worldSpacePosition.xyz);

                // Clip the fragment if it falls outside of any of the volumes
                clip(-sphereResult);

                // sample the texture
                fixed4 col = tex2D(_MainTex, vInfo.uv) * _Color;
                return col;
        }
        ENDCG
    }
    }
}