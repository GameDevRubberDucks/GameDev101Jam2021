Shader "CODE_UnlitVoxelWater"
{
    Properties
    {
        [NoScaleOffset] _WaterGradient("Water Gradient", 2D) = "white" {}
        Vector1_cd0b2b9536894524b6a7a4f0715a9bde("SineSpeed", Float) = 0
        Vector1_30b1110cb5c34cf9bf44af015bf70c4d("SineAmplitude", Float) = 0
        Vector1_22f907120f754213901669da8cad66d0("SineFrequency", Float) = 0
        Vector1_37475df265fb4b549ed4091781f0150d("BaseYPos (World Space)", Float) = 0
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
        float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
        float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
        float Vector1_22f907120f754213901669da8cad66d0;
        float Vector1_37475df265fb4b549ed4091781f0150d;
        CBUFFER_END

            // Object and Global properties
            TEXTURE2D(_WaterGradient);
            SAMPLER(sampler_WaterGradient);
            SAMPLER(SamplerState_Linear_Clamp);

            // Graph Functions

            void Unity_Multiply_float(float A, float B, out float Out)
            {
                Out = A * B;
            }

            void Unity_Add_float(float A, float B, out float Out)
            {
                Out = A + B;
            }

            void Unity_Sine_float(float In, out float Out)
            {
                Out = sin(In);
            }

            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
            {
                RGBA = float4(R, G, B, A);
                RGB = float3(R, G, B);
                RG = float2(R, G);
            }

            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
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
                float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
                float _Property_c77655038c794d1b8712312d8477b293_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                float _Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2;
                Unity_Multiply_float(_Property_c77655038c794d1b8712312d8477b293_Out_0, -1, _Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2);
                float _Property_7449a2851169448786b8a68de3d4f908_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_R_1 = IN.WorldSpacePosition[0];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2 = IN.WorldSpacePosition[1];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_B_3 = IN.WorldSpacePosition[2];
                float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_A_4 = 0;
                float _Property_5fdad03610cb46c1b5e1ceba8873d590_Out_0 = Vector1_37475df265fb4b549ed4091781f0150d;
                float _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2;
                Unity_Subtract_float(_Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2, _Property_5fdad03610cb46c1b5e1ceba8873d590_Out_0, _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2);
                float _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3;
                Unity_InverseLerp_float(_Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2, _Property_7449a2851169448786b8a68de3d4f908_Out_0, _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2, _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3);
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
                float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                float Vector1_22f907120f754213901669da8cad66d0;
                float Vector1_37475df265fb4b549ed4091781f0150d;
                CBUFFER_END

                    // Object and Global properties
                    TEXTURE2D(_WaterGradient);
                    SAMPLER(sampler_WaterGradient);

                    // Graph Functions

                    void Unity_Multiply_float(float A, float B, out float Out)
                    {
                        Out = A * B;
                    }

                    void Unity_Add_float(float A, float B, out float Out)
                    {
                        Out = A + B;
                    }

                    void Unity_Sine_float(float In, out float Out)
                    {
                        Out = sin(In);
                    }

                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                    {
                        RGBA = float4(R, G, B, A);
                        RGB = float3(R, G, B);
                        RG = float2(R, G);
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
                        float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                        float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                        float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                        float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                        float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                        float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                        Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                        float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                        float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                        float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                        float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                        float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                        float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                        float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                        Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                        float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                        Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                        float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                        float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                        Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                        float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                        Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                        float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                        float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                        Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                        float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                        Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                        float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                        float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                        float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                        Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                        float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                        description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
                        float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                        float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                        float Vector1_22f907120f754213901669da8cad66d0;
                        float Vector1_37475df265fb4b549ed4091781f0150d;
                        CBUFFER_END

                            // Object and Global properties
                            TEXTURE2D(_WaterGradient);
                            SAMPLER(sampler_WaterGradient);

                            // Graph Functions

                            void Unity_Multiply_float(float A, float B, out float Out)
                            {
                                Out = A * B;
                            }

                            void Unity_Add_float(float A, float B, out float Out)
                            {
                                Out = A + B;
                            }

                            void Unity_Sine_float(float In, out float Out)
                            {
                                Out = sin(In);
                            }

                            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                            {
                                RGBA = float4(R, G, B, A);
                                RGB = float3(R, G, B);
                                RG = float2(R, G);
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
                                float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                                float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                                float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                                float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                                float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                                Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                                float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                                float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                                float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                                float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                                float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                                float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                                float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                                Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                                float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                                Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                                float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                                float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                                Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                                float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                                Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                                float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                                Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                                float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                                Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                                float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                                float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                                float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                                Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                                float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                                description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
                                float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                float Vector1_22f907120f754213901669da8cad66d0;
                                float Vector1_37475df265fb4b549ed4091781f0150d;
                                CBUFFER_END

                                    // Object and Global properties
                                    TEXTURE2D(_WaterGradient);
                                    SAMPLER(sampler_WaterGradient);
                                    SAMPLER(SamplerState_Linear_Clamp);

                                    // Graph Functions

                                    void Unity_Multiply_float(float A, float B, out float Out)
                                    {
                                        Out = A * B;
                                    }

                                    void Unity_Add_float(float A, float B, out float Out)
                                    {
                                        Out = A + B;
                                    }

                                    void Unity_Sine_float(float In, out float Out)
                                    {
                                        Out = sin(In);
                                    }

                                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                    {
                                        RGBA = float4(R, G, B, A);
                                        RGB = float3(R, G, B);
                                        RG = float2(R, G);
                                    }

                                    void Unity_Subtract_float(float A, float B, out float Out)
                                    {
                                        Out = A - B;
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
                                        float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                                        float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                        float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                                        float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                                        float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                                        float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                                        float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                                        float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                                        float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                                        float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                                        Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                                        float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                                        Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                                        float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                                        float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                                        Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                                        float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                                        Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                                        float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                        float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                                        Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                                        float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                                        Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                                        float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                                        float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                                        float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                                        Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                                        float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                                        description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
                                        float _Property_c77655038c794d1b8712312d8477b293_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                        float _Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2;
                                        Unity_Multiply_float(_Property_c77655038c794d1b8712312d8477b293_Out_0, -1, _Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2);
                                        float _Property_7449a2851169448786b8a68de3d4f908_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_ae73fadf7b9a42d0b33bf136d07ca3bb_A_4 = 0;
                                        float _Property_5fdad03610cb46c1b5e1ceba8873d590_Out_0 = Vector1_37475df265fb4b549ed4091781f0150d;
                                        float _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2;
                                        Unity_Subtract_float(_Split_ae73fadf7b9a42d0b33bf136d07ca3bb_G_2, _Property_5fdad03610cb46c1b5e1ceba8873d590_Out_0, _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2);
                                        float _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3;
                                        Unity_InverseLerp_float(_Multiply_d93bca2d3ecc4dda9c5d1dcc4c9230d4_Out_2, _Property_7449a2851169448786b8a68de3d4f908_Out_0, _Subtract_3c20b941a4c848b3b4b4157f09d5464c_Out_2, _InverseLerp_1603daf9e8dc46558fade4fc959dd405_Out_3);
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
                                        float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                        float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                        float Vector1_22f907120f754213901669da8cad66d0;
                                        float Vector1_37475df265fb4b549ed4091781f0150d;
                                        CBUFFER_END

                                            // Object and Global properties
                                            TEXTURE2D(_WaterGradient);
                                            SAMPLER(sampler_WaterGradient);

                                            // Graph Functions

                                            void Unity_Multiply_float(float A, float B, out float Out)
                                            {
                                                Out = A * B;
                                            }

                                            void Unity_Add_float(float A, float B, out float Out)
                                            {
                                                Out = A + B;
                                            }

                                            void Unity_Sine_float(float In, out float Out)
                                            {
                                                Out = sin(In);
                                            }

                                            void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                            {
                                                RGBA = float4(R, G, B, A);
                                                RGB = float3(R, G, B);
                                                RG = float2(R, G);
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
                                                float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                                                float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                                                float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                                                float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                                                float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                                float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                                                float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                                                float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                                                float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                                                float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                                                float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                                                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                                                float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                                                Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                                                float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                                                Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                                                float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                                                Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                                                float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                                                float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                                                Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                                                float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                                                Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                                                float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                                float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                                                Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                                                float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                                                Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                                                float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                                                float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                                                float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                                                Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                                                float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                                                description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
                                                float Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                                float Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                                float Vector1_22f907120f754213901669da8cad66d0;
                                                float Vector1_37475df265fb4b549ed4091781f0150d;
                                                CBUFFER_END

                                                    // Object and Global properties
                                                    TEXTURE2D(_WaterGradient);
                                                    SAMPLER(sampler_WaterGradient);

                                                    // Graph Functions

                                                    void Unity_Multiply_float(float A, float B, out float Out)
                                                    {
                                                        Out = A * B;
                                                    }

                                                    void Unity_Add_float(float A, float B, out float Out)
                                                    {
                                                        Out = A + B;
                                                    }

                                                    void Unity_Sine_float(float In, out float Out)
                                                    {
                                                        Out = sin(In);
                                                    }

                                                    void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
                                                    {
                                                        RGBA = float4(R, G, B, A);
                                                        RGB = float3(R, G, B);
                                                        RG = float2(R, G);
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
                                                        float _Split_714a452811d14c32bdc54221e4b8d560_R_1 = IN.WorldSpacePosition[0];
                                                        float _Split_714a452811d14c32bdc54221e4b8d560_G_2 = IN.WorldSpacePosition[1];
                                                        float _Split_714a452811d14c32bdc54221e4b8d560_B_3 = IN.WorldSpacePosition[2];
                                                        float _Split_714a452811d14c32bdc54221e4b8d560_A_4 = 0;
                                                        float _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0 = Vector1_cd0b2b9536894524b6a7a4f0715a9bde;
                                                        float _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2;
                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_61a0ef9988ca4fb288ededa5f9ef0063_Out_0, _Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2);
                                                        float _Split_a7106c44947d424083a7662f31bd04ee_R_1 = IN.ObjectSpacePosition[0];
                                                        float _Split_a7106c44947d424083a7662f31bd04ee_G_2 = IN.ObjectSpacePosition[1];
                                                        float _Split_a7106c44947d424083a7662f31bd04ee_B_3 = IN.ObjectSpacePosition[2];
                                                        float _Split_a7106c44947d424083a7662f31bd04ee_A_4 = 0;
                                                        float _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2;
                                                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_R_1, _Split_a7106c44947d424083a7662f31bd04ee_R_1, _Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2);
                                                        float _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2;
                                                        Unity_Multiply_float(_Split_a7106c44947d424083a7662f31bd04ee_B_3, _Split_a7106c44947d424083a7662f31bd04ee_B_3, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2);
                                                        float _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2;
                                                        Unity_Add_float(_Multiply_35b917dc2ee245a0a627cba9c459c20d_Out_2, _Multiply_6adab057fb4f4ae9a566de5c66503cd3_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2);
                                                        float _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2;
                                                        Unity_Add_float(_Multiply_0652c0d8689b4d39a02aa51d831efddd_Out_2, _Add_a85b64b258a349caa6a0feb7ec5ee4d5_Out_2, _Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2);
                                                        float _Property_81e03dc242f34241ae9f2c634728406f_Out_0 = Vector1_22f907120f754213901669da8cad66d0;
                                                        float _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2;
                                                        Unity_Multiply_float(_Add_dcf709944a4e4ad89d50ceb7988ed794_Out_2, _Property_81e03dc242f34241ae9f2c634728406f_Out_0, _Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2);
                                                        float _Sine_213f9f359cd341c38f631f54283c951d_Out_1;
                                                        Unity_Sine_float(_Multiply_0eb6a017e2fb471781da9e22289b2b73_Out_2, _Sine_213f9f359cd341c38f631f54283c951d_Out_1);
                                                        float _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0 = Vector1_30b1110cb5c34cf9bf44af015bf70c4d;
                                                        float _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2;
                                                        Unity_Multiply_float(_Sine_213f9f359cd341c38f631f54283c951d_Out_1, _Property_8a0c5a9dd0dc4142b35647f8699ac478_Out_0, _Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2);
                                                        float _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2;
                                                        Unity_Add_float(_Multiply_58fa460036f942c6b47089fd02a7fe24_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_G_2, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2);
                                                        float4 _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4;
                                                        float3 _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5;
                                                        float2 _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6;
                                                        Unity_Combine_float(_Split_714a452811d14c32bdc54221e4b8d560_R_1, _Add_520d8f08f0b14fbc9f371a07a4d93bfa_Out_2, _Split_714a452811d14c32bdc54221e4b8d560_B_3, 0, _Combine_dc776343629c41df84f0f3bd2089e94c_RGBA_4, _Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5, _Combine_dc776343629c41df84f0f3bd2089e94c_RG_6);
                                                        float3 _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1 = TransformWorldToObject(_Combine_dc776343629c41df84f0f3bd2089e94c_RGB_5.xyz);
                                                        description.Position = _Transform_70f63bd229d442af92740c6b1ab840d2_Out_1;
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
