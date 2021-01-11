Shader "CODE_UnlitVoxelWaterWithGeom"
{
    Properties
    {
        [NoScaleOffset] _WaterGradient("Water Gradient", 2D) = "white" {}
        Vector1_4da92350050b4c29904e80bc6cab1335("Movement Speed", Float) = 0.1
        Vector1_1c4451286eeb45a1b85a861176373ccb("Noise Scale", Float) = 5
        Vector1_887daef417f94c428dd1280fb1ee9cf1("Noise Power", Float) = 0.1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
        SubShader
    {
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        struct GeomData
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
        };

        float4 WorldToClip(float3 _ws)
        {
            return mul(UNITY_MATRIX_VP, float4(_ws.x, _ws.y, _ws.z, 1.0f));
        }

        void CreateTriangle(GeomData _baseVert, inout TriangleStream<GeomData> _triStream, float3 _normal, float3 _offset1, float3 _offset2, float3 _offset3)
        {
            // Create the first vertex
            GeomData vert1 = _baseVert;
            vert1.positionWS = _baseVert.positionWS + _offset1;
            vert1.positionCS = WorldToClip(vert1.positionWS);
            //vert1.normalWS = _normal;

            // Create the second vertex
            GeomData vert2 = _baseVert;
            vert2.positionWS = _baseVert.positionWS + _offset2;
            vert2.positionCS = WorldToClip(vert2.positionWS);
            //vert2.normalWS = _normal;

            // Create the third vertex
            GeomData vert3 = _baseVert;
            vert3.positionWS = _baseVert.positionWS + _offset3;
            vert3.positionCS = WorldToClip(vert3.positionWS);
            //vert3.normalWS = _normal;

            // Create and export the triangle
            _triStream.Append(vert1);
            _triStream.Append(vert2);
            _triStream.Append(vert3);
            _triStream.RestartStrip();
        }

        [maxvertexcount(36)]
        void geom(point GeomData input[1], inout TriangleStream<GeomData> triStream)
        {
            // Set up the initial data
            GeomData vert = input;
            float size = 1.0f;
            float height = 5.0f;

            // Define the 8 different vertex positions for a cube
            // This is assuming we are looking straight down the z axis
            // (N = negative, P = positive)
            // (First letter = x axis, Second letter = z axis)
            // Ex: topNP -> N (-x), top (+y), P (+z)
            float3 topNP = float3(-size, size, size);
            float3 topPP = float3(size, size, size);
            float3 topPN = float3(size, size, -size);
            float3 topNN = float3(-size, size, -size);

            float3 botNP = float3(-size, -height, size);
            float3 botPP = float3(size, -height, size);
            float3 botPN = float3(size, -height, -size);
            float3 botNN = float3(-size, -height, -size);

            // Top
            float3 normTop = float3(0.0f, 1.0f, 0.0f);
            CreateTriangle(vert, triStream, normTop, topNP, topPN, topNN);
            CreateTriangle(vert, triStream, normTop, topNP, topPP, topPN);

            // Bottom
            float3 normBottom = float3(0.0f, -1.0f, 0.0f);
            CreateTriangle(vert, triStream, normBottom, botNP, botNN, botPN);
            CreateTriangle(vert, triStream, normBottom, botNP, botPN, botPP);

            // Left
            float3 normLeft = float3(-1.0f, 0.0f, 0.0f);
            CreateTriangle(vert, triStream, normLeft, topNN, botNP, topNP);
            CreateTriangle(vert, triStream, normLeft, botNP, topNN, botNN);

            // Right
            float3 normRight = float3(1.0f, 0.0f, 0.0f);
            CreateTriangle(vert, triStream, normRight, topPN, topPP, botPP);
            CreateTriangle(vert, triStream, normRight, topPN, botPP, botPN);

            // Front
            float3 normFront = float3(0.0f, 0.0f, 1.0f);
            CreateTriangle(vert, triStream, normFront, topNP, botPP, topPP);
            CreateTriangle(vert, triStream, normFront, topNP, botNP, botPP);

            // Back
            float3 normBack = float3(0.0f, 0.0f, -1.0f);
            CreateTriangle(vert, triStream, normBack, topNN, topPN, botPN);
            CreateTriangle(vert, triStream, normBack, topNN, botPN, botNN);
        }
        ENDHLSL

        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "UniversalMaterialType" = "Unlit"
            "Queue" = "Geometry"
        }
        Pass
        {
            Name "Pass"
            Tags
            {
        // LightMode: <None>
    }

    // Render State
    Cull Back
    Blend One Zero
    ZTest LEqual
    ZWrite On

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma geometry geom
        #pragma fragment frag

        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>

        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        // GraphKeywords: <None>

        // Defines
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        /*#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"*/

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

        PackedVaryings PackVaryings(Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz = input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings(PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _WaterGradient_TexelSize;
        float Vector1_4da92350050b4c29904e80bc6cab1335;
        float Vector1_1c4451286eeb45a1b85a861176373ccb;
        float Vector1_887daef417f94c428dd1280fb1ee9cf1;
        CBUFFER_END

            // Object and Global properties
            TEXTURE2D(_WaterGradient);
            SAMPLER(sampler_WaterGradient);
            SAMPLER(SamplerState_Linear_Clamp);

            // Graph Functions

            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
            {
                RGBA = float4(R, G, B, A);
                RGB = float3(R, G, B);
                RG = float2(R, G);
            }

            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }

            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
            {
                Out = UV * Tiling + Offset;
            }


            float2 Unity_GradientNoise_Dir_float(float2 p)
            {
                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                p = p % 289;
                // need full precision, otherwise half overflows when p > 1
                float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            {
                float2 p = UV * Scale;
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
            }

            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
            {
                Out = A + B;
            }

            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
            {
                Out = (T - A) / (B - A);
            }

            // Graph Vertex
            struct VertexDescription
            {
                float3 Position;
                float3 Normal;
                float3 Tangent;
            };

            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                description.Normal = IN.ObjectSpaceNormal;
                description.Tangent = IN.ObjectSpaceTangent;
                return description;
            }

            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
            };

            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float _Property_4afdab476e194c25a87241d3eae37448_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_R_1 = IN.WorldSpacePosition[0];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2 = IN.WorldSpacePosition[1];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_B_3 = IN.WorldSpacePosition[2];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_A_4 = 0;
                float _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3;
                Unity_InverseLerp_float(0, _Property_4afdab476e194c25a87241d3eae37448_Out_0, _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2, _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3);
                float4 _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0 = SAMPLE_TEXTURE2D(_WaterGradient, SamplerState_Linear_Clamp, (_InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3.xx));
                float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_R_4 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.r;
                float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_G_5 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.g;
                float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_B_6 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.b;
                float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_A_7 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.a;
                surface.BaseColor = (_SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.xyz);
                return surface;
            }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                output.ObjectSpaceNormal = input.normalOS;
                output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                output.ObjectSpaceTangent = input.tangentOS;
                output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                output.ObjectSpacePosition = input.positionOS;
                output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                output.TimeParameters = _TimeParameters.xyz;

                return output;
            }

            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                output.WorldSpacePosition = input.positionWS;
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                return output;
            }


            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On
                ColorMask 0

                // Debug
                // <None>

                // --------------------------------------------------
                // Pass

                HLSLPROGRAM

                // Pragmas
                #pragma target 2.0
                #pragma only_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma vertex vert
                #pragma geometry geom
                #pragma fragment frag

                // DotsInstancingOptions: <None>
                // HybridV1InjectedBuiltinProperties: <None>

                // Keywords
                // PassKeywords: <None>
                // GraphKeywords: <None>

                // Defines
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_SHADOWCASTER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                // --------------------------------------------------
                // Structs and Packing

                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                };
                struct VertexDescriptionInputs
                {
                    float3 ObjectSpaceNormal;
                    float3 WorldSpaceNormal;
                    float3 ObjectSpaceTangent;
                    float3 WorldSpaceTangent;
                    float3 ObjectSpaceBiTangent;
                    float3 WorldSpaceBiTangent;
                    float3 ObjectSpacePosition;
                    float3 WorldSpacePosition;
                    float3 TimeParameters;
                };
                struct PackedVaryings
                {
                    float4 positionCS : SV_POSITION;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                };

                PackedVaryings PackVaryings(Varyings input)
                {
                    PackedVaryings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                Varyings UnpackVaryings(PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }

                // --------------------------------------------------
                // Graph

                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 _WaterGradient_TexelSize;
                float Vector1_4da92350050b4c29904e80bc6cab1335;
                float Vector1_1c4451286eeb45a1b85a861176373ccb;
                float Vector1_887daef417f94c428dd1280fb1ee9cf1;
                CBUFFER_END

                    // Object and Global properties
                    TEXTURE2D(_WaterGradient);
                    SAMPLER(sampler_WaterGradient);

                    // Graph Functions

                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                    {
                        RGBA = float4(R, G, B, A);
                        RGB = float3(R, G, B);
                        RG = float2(R, G);
                    }

                    void Unity_Multiply_float(float A, float B, out float Out)
                    {
                        Out = A * B;
                    }

                    void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                    {
                        Out = UV * Tiling + Offset;
                    }


                    float2 Unity_GradientNoise_Dir_float(float2 p)
                    {
                        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                        p = p % 289;
                        // need full precision, otherwise half overflows when p > 1
                        float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                        x = (34 * x + 1) * x % 289;
                        x = frac(x / 41) * 2 - 1;
                        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
                    }

                    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
                    {
                        float2 p = UV * Scale;
                        float2 ip = floor(p);
                        float2 fp = frac(p);
                        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
                    }

                    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                    {
                        Out = A + B;
                    }

                    // Graph Vertex
                    struct VertexDescription
                    {
                        float3 Position;
                        float3 Normal;
                        float3 Tangent;
                    };

                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                        float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                        float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                        float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                        Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                        float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                        float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                        Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                        float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                        Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                        float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                        float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                        Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                        float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                        float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                        Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                        float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                        float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                        float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                        Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                        float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                        Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                        float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                        description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                        description.Normal = IN.ObjectSpaceNormal;
                        description.Tangent = IN.ObjectSpaceTangent;
                        return description;
                    }

                    // Graph Pixel
                    struct SurfaceDescription
                    {
                    };

                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        return surface;
                    }

                    // --------------------------------------------------
                    // Build Graph Inputs

                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                    {
                        VertexDescriptionInputs output;
                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                        output.ObjectSpaceNormal = input.normalOS;
                        output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                        output.ObjectSpaceTangent = input.tangentOS;
                        output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                        output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                        output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                        output.ObjectSpacePosition = input.positionOS;
                        output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                        output.TimeParameters = _TimeParameters.xyz;

                        return output;
                    }

                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                    {
                        SurfaceDescriptionInputs output;
                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                    #else
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                    #endif
                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                        return output;
                    }


                    // --------------------------------------------------
                    // Main

                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

                    ENDHLSL
                }
                Pass
                {
                    Name "DepthOnly"
                    Tags
                    {
                        "LightMode" = "DepthOnly"
                    }

                        // Render State
                        Cull Back
                        Blend One Zero
                        ZTest LEqual
                        ZWrite On
                        ColorMask 0

                        // Debug
                        // <None>

                        // --------------------------------------------------
                        // Pass

                        HLSLPROGRAM

                        // Pragmas
                        #pragma target 2.0
                        #pragma only_renderers gles gles3 glcore
                        #pragma multi_compile_instancing
                        #pragma vertex vert
                        #pragma geometry geom
                        #pragma fragment frag

                        // DotsInstancingOptions: <None>
                        // HybridV1InjectedBuiltinProperties: <None>

                        // Keywords
                        // PassKeywords: <None>
                        // GraphKeywords: <None>

                        // Defines
                        #define ATTRIBUTES_NEED_NORMAL
                        #define ATTRIBUTES_NEED_TANGENT
                        #define FEATURES_GRAPH_VERTEX
                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                        #define SHADERPASS SHADERPASS_DEPTHONLY
                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                        // Includes
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                        // --------------------------------------------------
                        // Structs and Packing

                        struct Attributes
                        {
                            float3 positionOS : POSITION;
                            float3 normalOS : NORMAL;
                            float4 tangentOS : TANGENT;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            uint instanceID : INSTANCEID_SEMANTIC;
                            #endif
                        };
                        struct Varyings
                        {
                            float4 positionCS : SV_POSITION;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                        };
                        struct SurfaceDescriptionInputs
                        {
                        };
                        struct VertexDescriptionInputs
                        {
                            float3 ObjectSpaceNormal;
                            float3 WorldSpaceNormal;
                            float3 ObjectSpaceTangent;
                            float3 WorldSpaceTangent;
                            float3 ObjectSpaceBiTangent;
                            float3 WorldSpaceBiTangent;
                            float3 ObjectSpacePosition;
                            float3 WorldSpacePosition;
                            float3 TimeParameters;
                        };
                        struct PackedVaryings
                        {
                            float4 positionCS : SV_POSITION;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                        };

                        PackedVaryings PackVaryings(Varyings input)
                        {
                            PackedVaryings output;
                            output.positionCS = input.positionCS;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }
                        Varyings UnpackVaryings(PackedVaryings input)
                        {
                            Varyings output;
                            output.positionCS = input.positionCS;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }

                        // --------------------------------------------------
                        // Graph

                        // Graph Properties
                        CBUFFER_START(UnityPerMaterial)
                        float4 _WaterGradient_TexelSize;
                        float Vector1_4da92350050b4c29904e80bc6cab1335;
                        float Vector1_1c4451286eeb45a1b85a861176373ccb;
                        float Vector1_887daef417f94c428dd1280fb1ee9cf1;
                        CBUFFER_END

                            // Object and Global properties
                            TEXTURE2D(_WaterGradient);
                            SAMPLER(sampler_WaterGradient);

                            // Graph Functions

                            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                            {
                                RGBA = float4(R, G, B, A);
                                RGB = float3(R, G, B);
                                RG = float2(R, G);
                            }

                            void Unity_Multiply_float(float A, float B, out float Out)
                            {
                                Out = A * B;
                            }

                            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                            {
                                Out = UV * Tiling + Offset;
                            }


                            float2 Unity_GradientNoise_Dir_float(float2 p)
                            {
                                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                                p = p % 289;
                                // need full precision, otherwise half overflows when p > 1
                                float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                                x = (34 * x + 1) * x % 289;
                                x = frac(x / 41) * 2 - 1;
                                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
                            }

                            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
                            {
                                float2 p = UV * Scale;
                                float2 ip = floor(p);
                                float2 fp = frac(p);
                                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
                            }

                            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                            {
                                Out = A + B;
                            }

                            // Graph Vertex
                            struct VertexDescription
                            {
                                float3 Position;
                                float3 Normal;
                                float3 Tangent;
                            };

                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                            {
                                VertexDescription description = (VertexDescription)0;
                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                                float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                                float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                                float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                                Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                                float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                                float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                                Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                                float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                                Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                                float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                                float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                                Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                                float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                                Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                                float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                                float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                                float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                                Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                                float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                                Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                                float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                                description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                                description.Normal = IN.ObjectSpaceNormal;
                                description.Tangent = IN.ObjectSpaceTangent;
                                return description;
                            }

                            // Graph Pixel
                            struct SurfaceDescription
                            {
                            };

                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                            {
                                SurfaceDescription surface = (SurfaceDescription)0;
                                return surface;
                            }

                            // --------------------------------------------------
                            // Build Graph Inputs

                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                            {
                                VertexDescriptionInputs output;
                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                output.ObjectSpaceNormal = input.normalOS;
                                output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                                output.ObjectSpaceTangent = input.tangentOS;
                                output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                                output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                                output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                                output.ObjectSpacePosition = input.positionOS;
                                output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                                output.TimeParameters = _TimeParameters.xyz;

                                return output;
                            }

                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                            {
                                SurfaceDescriptionInputs output;
                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                            #else
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                            #endif
                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                return output;
                            }


                            // --------------------------------------------------
                            // Main

                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

                            ENDHLSL
                        }
    }
        SubShader
                            {
                                Tags
                                {
                                    "RenderPipeline" = "UniversalPipeline"
                                    "RenderType" = "Opaque"
                                    "UniversalMaterialType" = "Unlit"
                                    "Queue" = "Geometry"
                                }
                                Pass
                                {
                                    Name "Pass"
                                    Tags
                                    {
                                // LightMode: <None>
                            }

                            // Render State
                            Cull Back
                            Blend One Zero
                            ZTest LEqual
                            ZWrite On

                                // Debug
                                // <None>

                                // --------------------------------------------------
                                // Pass

                                HLSLPROGRAM

                                // Pragmas
                                #pragma target 4.5
                                #pragma exclude_renderers gles gles3 glcore
                                #pragma multi_compile_instancing
                                #pragma multi_compile_fog
                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                #pragma vertex vert
                                #pragma geometry geom
                                #pragma fragment frag

                                // DotsInstancingOptions: <None>
                                // HybridV1InjectedBuiltinProperties: <None>

                                // Keywords
                                #pragma multi_compile _ LIGHTMAP_ON
                                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                                #pragma shader_feature _ _SAMPLE_GI
                                // GraphKeywords: <None>

                                // Defines
                                #define ATTRIBUTES_NEED_NORMAL
                                #define ATTRIBUTES_NEED_TANGENT
                                #define VARYINGS_NEED_POSITION_WS
                                #define FEATURES_GRAPH_VERTEX
                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                #define SHADERPASS SHADERPASS_UNLIT
                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                // Includes
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                                // --------------------------------------------------
                                // Structs and Packing

                                struct Attributes
                                {
                                    float3 positionOS : POSITION;
                                    float3 normalOS : NORMAL;
                                    float4 tangentOS : TANGENT;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    uint instanceID : INSTANCEID_SEMANTIC;
                                    #endif
                                };
                                struct Varyings
                                {
                                    float4 positionCS : SV_POSITION;
                                    float3 positionWS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                };
                                struct SurfaceDescriptionInputs
                                {
                                    float3 WorldSpacePosition;
                                };
                                struct VertexDescriptionInputs
                                {
                                    float3 ObjectSpaceNormal;
                                    float3 WorldSpaceNormal;
                                    float3 ObjectSpaceTangent;
                                    float3 WorldSpaceTangent;
                                    float3 ObjectSpaceBiTangent;
                                    float3 WorldSpaceBiTangent;
                                    float3 ObjectSpacePosition;
                                    float3 WorldSpacePosition;
                                    float3 TimeParameters;
                                };
                                struct PackedVaryings
                                {
                                    float4 positionCS : SV_POSITION;
                                    float3 interp0 : TEXCOORD0;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                };

                                PackedVaryings PackVaryings(Varyings input)
                                {
                                    PackedVaryings output;
                                    output.positionCS = input.positionCS;
                                    output.interp0.xyz = input.positionWS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }
                                Varyings UnpackVaryings(PackedVaryings input)
                                {
                                    Varyings output;
                                    output.positionCS = input.positionCS;
                                    output.positionWS = input.interp0.xyz;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }

                                // --------------------------------------------------
                                // Graph

                                // Graph Properties
                                CBUFFER_START(UnityPerMaterial)
                                float4 _WaterGradient_TexelSize;
                                float Vector1_4da92350050b4c29904e80bc6cab1335;
                                float Vector1_1c4451286eeb45a1b85a861176373ccb;
                                float Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                CBUFFER_END

                                    // Object and Global properties
                                    TEXTURE2D(_WaterGradient);
                                    SAMPLER(sampler_WaterGradient);
                                    SAMPLER(SamplerState_Linear_Clamp);

                                    // Graph Functions

                                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                    {
                                        RGBA = float4(R, G, B, A);
                                        RGB = float3(R, G, B);
                                        RG = float2(R, G);
                                    }

                                    void Unity_Multiply_float(float A, float B, out float Out)
                                    {
                                        Out = A * B;
                                    }

                                    void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                                    {
                                        Out = UV * Tiling + Offset;
                                    }


                                    float2 Unity_GradientNoise_Dir_float(float2 p)
                                    {
                                        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                                        p = p % 289;
                                        // need full precision, otherwise half overflows when p > 1
                                        float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                                        x = (34 * x + 1) * x % 289;
                                        x = frac(x / 41) * 2 - 1;
                                        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
                                    }

                                    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
                                    {
                                        float2 p = UV * Scale;
                                        float2 ip = floor(p);
                                        float2 fp = frac(p);
                                        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                                        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                                        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                                        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                                        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                                        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
                                    }

                                    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                                    {
                                        Out = A + B;
                                    }

                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                    {
                                        Out = (T - A) / (B - A);
                                    }

                                    // Graph Vertex
                                    struct VertexDescription
                                    {
                                        float3 Position;
                                        float3 Normal;
                                        float3 Tangent;
                                    };

                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                    {
                                        VertexDescription description = (VertexDescription)0;
                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                                        float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                                        float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                                        float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                                        Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                                        float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                                        float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                                        float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                                        Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                                        float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                                        float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                                        Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                                        float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                        float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                                        Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                                        float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                                        float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                                        float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                                        Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                                        float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                                        Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                                        float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                                        description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                                        description.Normal = IN.ObjectSpaceNormal;
                                        description.Tangent = IN.ObjectSpaceTangent;
                                        return description;
                                    }

                                    // Graph Pixel
                                    struct SurfaceDescription
                                    {
                                        float3 BaseColor;
                                    };

                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                    {
                                        SurfaceDescription surface = (SurfaceDescription)0;
                                        float _Property_4afdab476e194c25a87241d3eae37448_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_A_4 = 0;
                                        float _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3;
                                        Unity_InverseLerp_float(0, _Property_4afdab476e194c25a87241d3eae37448_Out_0, _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2, _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3);
                                        float4 _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0 = SAMPLE_TEXTURE2D(_WaterGradient, SamplerState_Linear_Clamp, (_InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3.xx));
                                        float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_R_4 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.r;
                                        float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_G_5 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.g;
                                        float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_B_6 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.b;
                                        float _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_A_7 = _SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.a;
                                        surface.BaseColor = (_SampleTexture2D_a8766ccfd1c04ce2a72ed505dbf67d59_RGBA_0.xyz);
                                        return surface;
                                    }

                                    // --------------------------------------------------
                                    // Build Graph Inputs

                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                    {
                                        VertexDescriptionInputs output;
                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                        output.ObjectSpaceNormal = input.normalOS;
                                        output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                                        output.ObjectSpaceTangent = input.tangentOS;
                                        output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                                        output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                                        output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                                        output.ObjectSpacePosition = input.positionOS;
                                        output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                                        output.TimeParameters = _TimeParameters.xyz;

                                        return output;
                                    }

                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                    {
                                        SurfaceDescriptionInputs output;
                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                                        output.WorldSpacePosition = input.positionWS;
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                    #else
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                    #endif
                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                        return output;
                                    }


                                    // --------------------------------------------------
                                    // Main

                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"

                                    ENDHLSL
                                }
                                Pass
                                {
                                    Name "ShadowCaster"
                                    Tags
                                    {
                                        "LightMode" = "ShadowCaster"
                                    }

                                        // Render State
                                        Cull Back
                                        Blend One Zero
                                        ZTest LEqual
                                        ZWrite On
                                        ColorMask 0

                                        // Debug
                                        // <None>

                                        // --------------------------------------------------
                                        // Pass

                                        HLSLPROGRAM

                                        // Pragmas
                                        #pragma target 4.5
                                        #pragma exclude_renderers gles gles3 glcore
                                        #pragma multi_compile_instancing
                                        #pragma multi_compile _ DOTS_INSTANCING_ON
                                        #pragma vertex vert
                                        #pragma geometry geom
                                        #pragma fragment frag

                                        // DotsInstancingOptions: <None>
                                        // HybridV1InjectedBuiltinProperties: <None>

                                        // Keywords
                                        // PassKeywords: <None>
                                        // GraphKeywords: <None>

                                        // Defines
                                        #define ATTRIBUTES_NEED_NORMAL
                                        #define ATTRIBUTES_NEED_TANGENT
                                        #define FEATURES_GRAPH_VERTEX
                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                        #define SHADERPASS SHADERPASS_SHADOWCASTER
                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                        // Includes
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                                        // --------------------------------------------------
                                        // Structs and Packing

                                        struct Attributes
                                        {
                                            float3 positionOS : POSITION;
                                            float3 normalOS : NORMAL;
                                            float4 tangentOS : TANGENT;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            uint instanceID : INSTANCEID_SEMANTIC;
                                            #endif
                                        };
                                        struct Varyings
                                        {
                                            float4 positionCS : SV_POSITION;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                        };
                                        struct SurfaceDescriptionInputs
                                        {
                                        };
                                        struct VertexDescriptionInputs
                                        {
                                            float3 ObjectSpaceNormal;
                                            float3 WorldSpaceNormal;
                                            float3 ObjectSpaceTangent;
                                            float3 WorldSpaceTangent;
                                            float3 ObjectSpaceBiTangent;
                                            float3 WorldSpaceBiTangent;
                                            float3 ObjectSpacePosition;
                                            float3 WorldSpacePosition;
                                            float3 TimeParameters;
                                        };
                                        struct PackedVaryings
                                        {
                                            float4 positionCS : SV_POSITION;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                        };

                                        PackedVaryings PackVaryings(Varyings input)
                                        {
                                            PackedVaryings output;
                                            output.positionCS = input.positionCS;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }
                                        Varyings UnpackVaryings(PackedVaryings input)
                                        {
                                            Varyings output;
                                            output.positionCS = input.positionCS;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }

                                        // --------------------------------------------------
                                        // Graph

                                        // Graph Properties
                                        CBUFFER_START(UnityPerMaterial)
                                        float4 _WaterGradient_TexelSize;
                                        float Vector1_4da92350050b4c29904e80bc6cab1335;
                                        float Vector1_1c4451286eeb45a1b85a861176373ccb;
                                        float Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                        CBUFFER_END

                                            // Object and Global properties
                                            TEXTURE2D(_WaterGradient);
                                            SAMPLER(sampler_WaterGradient);

                                            // Graph Functions

                                            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                            {
                                                RGBA = float4(R, G, B, A);
                                                RGB = float3(R, G, B);
                                                RG = float2(R, G);
                                            }

                                            void Unity_Multiply_float(float A, float B, out float Out)
                                            {
                                                Out = A * B;
                                            }

                                            void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                                            {
                                                Out = UV * Tiling + Offset;
                                            }


                                            float2 Unity_GradientNoise_Dir_float(float2 p)
                                            {
                                                // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                                                p = p % 289;
                                                // need full precision, otherwise half overflows when p > 1
                                                float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                                                x = (34 * x + 1) * x % 289;
                                                x = frac(x / 41) * 2 - 1;
                                                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
                                            }

                                            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
                                            {
                                                float2 p = UV * Scale;
                                                float2 ip = floor(p);
                                                float2 fp = frac(p);
                                                float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                                                float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                                                float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                                                float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                                                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                                                Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
                                            }

                                            void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                                            {
                                                Out = A + B;
                                            }

                                            // Graph Vertex
                                            struct VertexDescription
                                            {
                                                float3 Position;
                                                float3 Normal;
                                                float3 Tangent;
                                            };

                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                            {
                                                VertexDescription description = (VertexDescription)0;
                                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                                                float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                                                float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                                                float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                                                float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                                                Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                                                float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                                                float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                                                float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                                                Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                                                float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                                                float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                                                Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                                                float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                                float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                                                Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                                                float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                                                float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                                                float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                                                Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                                                float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                                                Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                                                float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                                                description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                                                description.Normal = IN.ObjectSpaceNormal;
                                                description.Tangent = IN.ObjectSpaceTangent;
                                                return description;
                                            }

                                            // Graph Pixel
                                            struct SurfaceDescription
                                            {
                                            };

                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                            {
                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                return surface;
                                            }

                                            // --------------------------------------------------
                                            // Build Graph Inputs

                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                            {
                                                VertexDescriptionInputs output;
                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                output.ObjectSpaceNormal = input.normalOS;
                                                output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                                                output.ObjectSpaceTangent = input.tangentOS;
                                                output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                                                output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                                                output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                                                output.ObjectSpacePosition = input.positionOS;
                                                output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                                                output.TimeParameters = _TimeParameters.xyz;

                                                return output;
                                            }

                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                            {
                                                SurfaceDescriptionInputs output;
                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                            #else
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                            #endif
                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                return output;
                                            }


                                            // --------------------------------------------------
                                            // Main

                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

                                            ENDHLSL
                                        }
                                        Pass
                                        {
                                            Name "DepthOnly"
                                            Tags
                                            {
                                                "LightMode" = "DepthOnly"
                                            }

                                                // Render State
                                                Cull Back
                                                Blend One Zero
                                                ZTest LEqual
                                                ZWrite On
                                                ColorMask 0

                                                // Debug
                                                // <None>

                                                // --------------------------------------------------
                                                // Pass

                                                HLSLPROGRAM

                                                // Pragmas
                                                #pragma target 4.5
                                                #pragma exclude_renderers gles gles3 glcore
                                                #pragma multi_compile_instancing
                                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                                #pragma vertex vert
                                                #pragma geometry geom
                                                #pragma fragment frag

                                                // DotsInstancingOptions: <None>
                                                // HybridV1InjectedBuiltinProperties: <None>

                                                // Keywords
                                                // PassKeywords: <None>
                                                // GraphKeywords: <None>

                                                // Defines
                                                #define ATTRIBUTES_NEED_NORMAL
                                                #define ATTRIBUTES_NEED_TANGENT
                                                #define FEATURES_GRAPH_VERTEX
                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                #define SHADERPASS SHADERPASS_DEPTHONLY
                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                                // Includes
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                                                // --------------------------------------------------
                                                // Structs and Packing

                                                struct Attributes
                                                {
                                                    float3 positionOS : POSITION;
                                                    float3 normalOS : NORMAL;
                                                    float4 tangentOS : TANGENT;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    uint instanceID : INSTANCEID_SEMANTIC;
                                                    #endif
                                                };
                                                struct Varyings
                                                {
                                                    float4 positionCS : SV_POSITION;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                };
                                                struct SurfaceDescriptionInputs
                                                {
                                                };
                                                struct VertexDescriptionInputs
                                                {
                                                    float3 ObjectSpaceNormal;
                                                    float3 WorldSpaceNormal;
                                                    float3 ObjectSpaceTangent;
                                                    float3 WorldSpaceTangent;
                                                    float3 ObjectSpaceBiTangent;
                                                    float3 WorldSpaceBiTangent;
                                                    float3 ObjectSpacePosition;
                                                    float3 WorldSpacePosition;
                                                    float3 TimeParameters;
                                                };
                                                struct PackedVaryings
                                                {
                                                    float4 positionCS : SV_POSITION;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                };

                                                PackedVaryings PackVaryings(Varyings input)
                                                {
                                                    PackedVaryings output;
                                                    output.positionCS = input.positionCS;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }
                                                Varyings UnpackVaryings(PackedVaryings input)
                                                {
                                                    Varyings output;
                                                    output.positionCS = input.positionCS;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }

                                                // --------------------------------------------------
                                                // Graph

                                                // Graph Properties
                                                CBUFFER_START(UnityPerMaterial)
                                                float4 _WaterGradient_TexelSize;
                                                float Vector1_4da92350050b4c29904e80bc6cab1335;
                                                float Vector1_1c4451286eeb45a1b85a861176373ccb;
                                                float Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                                CBUFFER_END

                                                    // Object and Global properties
                                                    TEXTURE2D(_WaterGradient);
                                                    SAMPLER(sampler_WaterGradient);

                                                    // Graph Functions

                                                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                                    {
                                                        RGBA = float4(R, G, B, A);
                                                        RGB = float3(R, G, B);
                                                        RG = float2(R, G);
                                                    }

                                                    void Unity_Multiply_float(float A, float B, out float Out)
                                                    {
                                                        Out = A * B;
                                                    }

                                                    void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
                                                    {
                                                        Out = UV * Tiling + Offset;
                                                    }


                                                    float2 Unity_GradientNoise_Dir_float(float2 p)
                                                    {
                                                        // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
                                                        p = p % 289;
                                                        // need full precision, otherwise half overflows when p > 1
                                                        float x = float(34 * p.x + 1) * p.x % 289 + p.y;
                                                        x = (34 * x + 1) * x % 289;
                                                        x = frac(x / 41) * 2 - 1;
                                                        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
                                                    }

                                                    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
                                                    {
                                                        float2 p = UV * Scale;
                                                        float2 ip = floor(p);
                                                        float2 fp = frac(p);
                                                        float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
                                                        float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
                                                        float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
                                                        float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
                                                        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                                                        Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
                                                    }

                                                    void Unity_Add_float3(float3 A, float3 B, out float3 Out)
                                                    {
                                                        Out = A + B;
                                                    }

                                                    // Graph Vertex
                                                    struct VertexDescription
                                                    {
                                                        float3 Position;
                                                        float3 Normal;
                                                        float3 Tangent;
                                                    };

                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                    {
                                                        VertexDescription description = (VertexDescription)0;
                                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_R_1 = IN.WorldSpacePosition[0];
                                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_G_2 = IN.WorldSpacePosition[1];
                                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3 = IN.WorldSpacePosition[2];
                                                        float _Split_f49fb97866984cff8a33297ad0e1e2cf_A_4 = 0;
                                                        float4 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4;
                                                        float3 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5;
                                                        float2 _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6;
                                                        Unity_Combine_float(_Split_f49fb97866984cff8a33297ad0e1e2cf_R_1, _Split_f49fb97866984cff8a33297ad0e1e2cf_B_3, 0, 0, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGBA_4, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RGB_5, _Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6);
                                                        float _Property_4842389f6a34497b8f98a16481ea824a_Out_0 = Vector1_4da92350050b4c29904e80bc6cab1335;
                                                        float _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2;
                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_4842389f6a34497b8f98a16481ea824a_Out_0, _Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2);
                                                        float2 _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3;
                                                        Unity_TilingAndOffset_float(_Combine_fce58a1e1f3448699ab0494eed1d55d6_RG_6, float2 (1, 1), (_Multiply_d2bc150d3ccc4601b26aa117c7d785d4_Out_2.xx), _TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3);
                                                        float _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0 = Vector1_1c4451286eeb45a1b85a861176373ccb;
                                                        float _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2;
                                                        Unity_GradientNoise_float(_TilingAndOffset_519331a759cb4ffb8caf9afe8c007cf7_Out_3, _Property_18ab5fab4a2d484a82219b707bc34b4a_Out_0, _GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2);
                                                        float _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0 = Vector1_887daef417f94c428dd1280fb1ee9cf1;
                                                        float _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2;
                                                        Unity_Multiply_float(_GradientNoise_6c4b8fd8199c45a0a0af84cd522b8f31_Out_2, _Property_b9c1caf5884d47069bc9568f51dc0a1e_Out_0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2);
                                                        float4 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4;
                                                        float3 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5;
                                                        float2 _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6;
                                                        Unity_Combine_float(0, _Multiply_8c7eb4486be440fa987bfac837dc36a5_Out_2, 0, 0, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGBA_4, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RG_6);
                                                        float3 _Add_3708d3c4b6644c919d278593c3571d0f_Out_2;
                                                        Unity_Add_float3(IN.WorldSpacePosition, _Combine_663dd14cf25646cdae3e7caf2a94e9c1_RGB_5, _Add_3708d3c4b6644c919d278593c3571d0f_Out_2);
                                                        float3 _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1 = TransformWorldToObject(_Add_3708d3c4b6644c919d278593c3571d0f_Out_2.xyz);
                                                        description.Position = _Transform_626a30dfd22c412795f79bbaa14a6ae6_Out_1;
                                                        description.Normal = IN.ObjectSpaceNormal;
                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                        return description;
                                                    }

                                                    // Graph Pixel
                                                    struct SurfaceDescription
                                                    {
                                                    };

                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                    {
                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                        return surface;
                                                    }

                                                    // --------------------------------------------------
                                                    // Build Graph Inputs

                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                    {
                                                        VertexDescriptionInputs output;
                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                        output.ObjectSpaceNormal = input.normalOS;
                                                        output.WorldSpaceNormal = TransformObjectToWorldNormal(input.normalOS);
                                                        output.ObjectSpaceTangent = input.tangentOS;
                                                        output.WorldSpaceTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                                                        output.ObjectSpaceBiTangent = normalize(cross(input.normalOS, input.tangentOS) * (input.tangentOS.w > 0.0f ? 1.0f : -1.0f)* GetOddNegativeScale());
                                                        output.WorldSpaceBiTangent = TransformObjectToWorldDir(output.ObjectSpaceBiTangent);
                                                        output.ObjectSpacePosition = input.positionOS;
                                                        output.WorldSpacePosition = TransformObjectToWorld(input.positionOS);
                                                        output.TimeParameters = _TimeParameters.xyz;

                                                        return output;
                                                    }

                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                    {
                                                        SurfaceDescriptionInputs output;
                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                    #else
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                    #endif
                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                        return output;
                                                    }


                                                    // --------------------------------------------------
                                                    // Main

                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

                                                    ENDHLSL
                                                }
                            }
                                FallBack "Hidden/Shader Graph/FallbackError"
}
