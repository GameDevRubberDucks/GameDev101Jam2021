Shader "LitRippleWaterWithClipping_CODE"
{
    Properties
    {
        [NoScaleOffset] Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194("WaterGradient", 2D) = "white" {}
        Vector1_20316dd03bb141e5a52680117f6e4994("SineSpeed", Float) = 5
        Vector1_20a623678efd46938e5f9485caef8e62("SineAmplitude", Float) = 4
        Vector1_339876ac601549b7a0c475d8fc6c4dde("SineFrequency", Float) = 0.08
        Vector1_949be71b581b4ff8a0ea7c2828a0774e("BaseYPos (World Space)", Float) = 0
        Vector1_f8515326c18542709304194130e489cf("Metallic", Float) = 0
        Vector1_f8515326c18542709304194130e489cf_1("Smoothness", Float) = 0.5
        Vector1_ae2046b7e5204627939c74ee8ff49687("Ambient Occlusion", Float) = 1
        [HDR]Color_7bf11e24f10942e9a75fc363b7f14b40("Emission", Color) = (0, 0, 0, 0)
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        HLSLINCLUDE

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        struct GeomData
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            float3 normalWS : TEXCOORD1;
            float4 tangentWS : TEXCOORD2;
            float3 viewDirectionWS : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh : TEXCOORD5;
            #endif
            float4 fogFactorAndVertexLight : TEXCOORD6;
            float4 shadowCoord : TEXCOORD7;
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
            vert1.normalWS = _normal;

            // Create the second vertex
            GeomData vert2 = _baseVert;
            vert2.positionWS = _baseVert.positionWS + _offset2;
            vert2.positionCS = WorldToClip(vert2.positionWS);
            vert2.normalWS = _normal;

            // Create the third vertex
            GeomData vert3 = _baseVert;
            vert3.positionWS = _baseVert.positionWS + _offset3;
            vert3.positionCS = WorldToClip(vert3.positionWS);
            vert3.normalWS = _normal;

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

            // Define the 8 different vertex positions for a cube
            // This is assuming we are looking straight down the z axis
            // (N = negative, P = positive)
            // (First letter = x axis, Second letter = z axis)
            // Ex: topNP -> N (-x), top (+y), P (+z)
            float3 topNP = float3(-size, size, size);
            float3 topPP = float3(size, size, size);
            float3 topPN = float3(size, size, -size);
            float3 topNN = float3(-size, size, -size);

            float3 botNP = float3(-size, -size, size);
            float3 botPP = float3(size, -size, size);
            float3 botPN = float3(size, -size, -size);
            float3 botNN = float3(-size, -size, -size);

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
            "UniversalMaterialType" = "Lit"
            "Queue" = "AlphaTest"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
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
        #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        // GraphKeywords: <None>

        // Defines
        #define _AlphaClip 1
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
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
            float3 TangentSpaceNormal;
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
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
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
            output.interp1.xyz = input.normalWS;
            output.interp2.xyzw = input.tangentWS;
            output.interp3.xyz = input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy = input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz = input.sh;
            #endif
            output.interp6.xyzw = input.fogFactorAndVertexLight;
            output.interp7.xyzw = input.shadowCoord;
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
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
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
        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
        float Vector1_20316dd03bb141e5a52680117f6e4994;
        float Vector1_20a623678efd46938e5f9485caef8e62;
        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
        float Vector1_f8515326c18542709304194130e489cf;
        float Vector1_f8515326c18542709304194130e489cf_1;
        float Vector1_ae2046b7e5204627939c74ee8ff49687;
        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
        CBUFFER_END

            // Object and Global properties
            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
            TEXTURE2D(_SphereData);
            SAMPLER(sampler_SphereData);
            float4 _SphereData_TexelSize;
            TEXTURE2D(_BoxData);
            SAMPLER(sampler_BoxData);
            float4 _BoxData_TexelSize;
            TEXTURE2D(_ConeData);
            SAMPLER(sampler_ConeData);
            float4 _ConeData_TexelSize;
            float _NumSpheresActive;
            float _NumBoxesActive;
            float _NumConesActive;
            SAMPLER(SamplerState_Linear_Clamp);
            SAMPLER(SamplerState_Point_Clamp);

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

            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
            {
                float3 WorldSpaceNormal;
                float3 WorldSpaceTangent;
                float3 WorldSpaceBiTangent;
                float3 ObjectSpacePosition;
                float3 WorldSpacePosition;
                float3 TimeParameters;
            };

            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
            {
                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
            }

            void Unity_Subtract_float(float A, float B, out float Out)
            {
                Out = A - B;
            }

            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
            {
                Out = (T - A) / (B - A);
            }

            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
            {
                float3 WorldSpacePosition;
            };

            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
            {
                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
            }

            // 596131a919f37b2a31c2db359d7db57a
            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
            {
                float3 WorldSpacePosition;
            };

            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
            {
                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
            }

            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
            {
                Out = Predicate ? True : False;
            }

            void Unity_Minimum_float(float A, float B, out float Out)
            {
                Out = min(A, B);
            };

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
                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                description.Normal = IN.ObjectSpaceNormal;
                description.Tangent = IN.ObjectSpaceTangent;
                return description;
            }

            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
                float3 NormalTS;
                float3 Emission;
                float Metallic;
                float Smoothness;
                float Occlusion;
                float Alpha;
                float AlphaClipThreshold;
            };

            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                float4 _Property_d3a4c2b7db6047fab68359468da1873d_Out_0 = IsGammaSpace() ? LinearToSRGB(Color_7bf11e24f10942e9a75fc363b7f14b40) : Color_7bf11e24f10942e9a75fc363b7f14b40;
                float _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0 = Vector1_f8515326c18542709304194130e489cf;
                float _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0 = Vector1_f8515326c18542709304194130e489cf_1;
                float _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0 = Vector1_ae2046b7e5204627939c74ee8ff49687;
                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                surface.NormalTS = IN.TangentSpaceNormal;
                surface.Emission = (_Property_d3a4c2b7db6047fab68359468da1873d_Out_0.xyz);
                surface.Metallic = _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0;
                surface.Smoothness = _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0;
                surface.Occlusion = _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0;
                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                surface.AlphaClipThreshold = 0.01;
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



                output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


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
            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
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
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
                #pragma multi_compile _ _GBUFFER_NORMALS_OCT
                // GraphKeywords: <None>

                // Defines
                #define _AlphaClip 1
                #define _NORMALMAP 1
                #define _NORMAL_DROPOFF_TS 1
                #define ATTRIBUTES_NEED_NORMAL
                #define ATTRIBUTES_NEED_TANGENT
                #define ATTRIBUTES_NEED_TEXCOORD1
                #define VARYINGS_NEED_POSITION_WS
                #define VARYINGS_NEED_NORMAL_WS
                #define VARYINGS_NEED_TANGENT_WS
                #define VARYINGS_NEED_VIEWDIRECTION_WS
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_GBUFFER
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                // --------------------------------------------------
                // Structs and Packing

                struct Attributes
                {
                    float3 positionOS : POSITION;
                    float3 normalOS : NORMAL;
                    float4 tangentOS : TANGENT;
                    float4 uv1 : TEXCOORD1;
                    #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                };
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS;
                    float3 normalWS;
                    float4 tangentWS;
                    float3 viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    float2 lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 sh;
                    #endif
                    float4 fogFactorAndVertexLight;
                    float4 shadowCoord;
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
                    float3 TangentSpaceNormal;
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
                    float3 interp1 : TEXCOORD1;
                    float4 interp2 : TEXCOORD2;
                    float3 interp3 : TEXCOORD3;
                    #if defined(LIGHTMAP_ON)
                    float2 interp4 : TEXCOORD4;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    float3 interp5 : TEXCOORD5;
                    #endif
                    float4 interp6 : TEXCOORD6;
                    float4 interp7 : TEXCOORD7;
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
                    output.interp1.xyz = input.normalWS;
                    output.interp2.xyzw = input.tangentWS;
                    output.interp3.xyz = input.viewDirectionWS;
                    #if defined(LIGHTMAP_ON)
                    output.interp4.xy = input.lightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.interp5.xyz = input.sh;
                    #endif
                    output.interp6.xyzw = input.fogFactorAndVertexLight;
                    output.interp7.xyzw = input.shadowCoord;
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
                    output.normalWS = input.interp1.xyz;
                    output.tangentWS = input.interp2.xyzw;
                    output.viewDirectionWS = input.interp3.xyz;
                    #if defined(LIGHTMAP_ON)
                    output.lightmapUV = input.interp4.xy;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.sh = input.interp5.xyz;
                    #endif
                    output.fogFactorAndVertexLight = input.interp6.xyzw;
                    output.shadowCoord = input.interp7.xyzw;
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
                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                float Vector1_20316dd03bb141e5a52680117f6e4994;
                float Vector1_20a623678efd46938e5f9485caef8e62;
                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                float Vector1_f8515326c18542709304194130e489cf;
                float Vector1_f8515326c18542709304194130e489cf_1;
                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                CBUFFER_END

                    // Object and Global properties
                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                    TEXTURE2D(_SphereData);
                    SAMPLER(sampler_SphereData);
                    float4 _SphereData_TexelSize;
                    TEXTURE2D(_BoxData);
                    SAMPLER(sampler_BoxData);
                    float4 _BoxData_TexelSize;
                    TEXTURE2D(_ConeData);
                    SAMPLER(sampler_ConeData);
                    float4 _ConeData_TexelSize;
                    float _NumSpheresActive;
                    float _NumBoxesActive;
                    float _NumConesActive;
                    SAMPLER(SamplerState_Linear_Clamp);
                    SAMPLER(SamplerState_Point_Clamp);

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

                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                    {
                        float3 WorldSpaceNormal;
                        float3 WorldSpaceTangent;
                        float3 WorldSpaceBiTangent;
                        float3 ObjectSpacePosition;
                        float3 WorldSpacePosition;
                        float3 TimeParameters;
                    };

                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                    {
                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                    }

                    void Unity_Subtract_float(float A, float B, out float Out)
                    {
                        Out = A - B;
                    }

                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                    {
                        Out = (T - A) / (B - A);
                    }

                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                    {
                        float3 WorldSpacePosition;
                    };

                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                    {
                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                    }

                    // 596131a919f37b2a31c2db359d7db57a
                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                    {
                        float3 WorldSpacePosition;
                    };

                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                    {
                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                    }

                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                    {
                        Out = Predicate ? True : False;
                    }

                    void Unity_Minimum_float(float A, float B, out float Out)
                    {
                        Out = min(A, B);
                    };

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
                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                        description.Normal = IN.ObjectSpaceNormal;
                        description.Tangent = IN.ObjectSpaceTangent;
                        return description;
                    }

                    // Graph Pixel
                    struct SurfaceDescription
                    {
                        float3 BaseColor;
                        float3 NormalTS;
                        float3 Emission;
                        float Metallic;
                        float Smoothness;
                        float Occlusion;
                        float Alpha;
                        float AlphaClipThreshold;
                    };

                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                        float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                        float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                        float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                        Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                        float4 _Property_d3a4c2b7db6047fab68359468da1873d_Out_0 = IsGammaSpace() ? LinearToSRGB(Color_7bf11e24f10942e9a75fc363b7f14b40) : Color_7bf11e24f10942e9a75fc363b7f14b40;
                        float _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0 = Vector1_f8515326c18542709304194130e489cf;
                        float _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0 = Vector1_f8515326c18542709304194130e489cf_1;
                        float _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0 = Vector1_ae2046b7e5204627939c74ee8ff49687;
                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                        surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                        surface.NormalTS = IN.TangentSpaceNormal;
                        surface.Emission = (_Property_d3a4c2b7db6047fab68359468da1873d_Out_0.xyz);
                        surface.Metallic = _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0;
                        surface.Smoothness = _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0;
                        surface.Occlusion = _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0;
                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                        surface.AlphaClipThreshold = 0.01;
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



                        output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


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
                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

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
                        #define _AlphaClip 1
                        #define _NORMALMAP 1
                        #define _NORMAL_DROPOFF_TS 1
                        #define ATTRIBUTES_NEED_NORMAL
                        #define ATTRIBUTES_NEED_TANGENT
                        #define VARYINGS_NEED_POSITION_WS
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
                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                        float Vector1_20a623678efd46938e5f9485caef8e62;
                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                        float Vector1_f8515326c18542709304194130e489cf;
                        float Vector1_f8515326c18542709304194130e489cf_1;
                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                        CBUFFER_END

                            // Object and Global properties
                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                            TEXTURE2D(_SphereData);
                            SAMPLER(sampler_SphereData);
                            float4 _SphereData_TexelSize;
                            TEXTURE2D(_BoxData);
                            SAMPLER(sampler_BoxData);
                            float4 _BoxData_TexelSize;
                            TEXTURE2D(_ConeData);
                            SAMPLER(sampler_ConeData);
                            float4 _ConeData_TexelSize;
                            float _NumSpheresActive;
                            float _NumBoxesActive;
                            float _NumConesActive;
                            SAMPLER(SamplerState_Linear_Clamp);
                            SAMPLER(SamplerState_Point_Clamp);

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

                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                            {
                                float3 WorldSpaceNormal;
                                float3 WorldSpaceTangent;
                                float3 WorldSpaceBiTangent;
                                float3 ObjectSpacePosition;
                                float3 WorldSpacePosition;
                                float3 TimeParameters;
                            };

                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                            {
                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                            }

                            void Unity_Subtract_float(float A, float B, out float Out)
                            {
                                Out = A - B;
                            }

                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                            {
                                Out = (T - A) / (B - A);
                            }

                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                            {
                                float3 WorldSpacePosition;
                            };

                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                            {
                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                            }

                            // 596131a919f37b2a31c2db359d7db57a
                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                            {
                                float3 WorldSpacePosition;
                            };

                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                            {
                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                            }

                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                            {
                                Out = Predicate ? True : False;
                            }

                            void Unity_Minimum_float(float A, float B, out float Out)
                            {
                                Out = min(A, B);
                            };

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
                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                description.Normal = IN.ObjectSpaceNormal;
                                description.Tangent = IN.ObjectSpaceTangent;
                                return description;
                            }

                            // Graph Pixel
                            struct SurfaceDescription
                            {
                                float Alpha;
                                float AlphaClipThreshold;
                            };

                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                            {
                                SurfaceDescription surface = (SurfaceDescription)0;
                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                surface.AlphaClipThreshold = 0.01;
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
                                #define _AlphaClip 1
                                #define _NORMALMAP 1
                                #define _NORMAL_DROPOFF_TS 1
                                #define ATTRIBUTES_NEED_NORMAL
                                #define ATTRIBUTES_NEED_TANGENT
                                #define VARYINGS_NEED_POSITION_WS
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
                                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                float Vector1_20316dd03bb141e5a52680117f6e4994;
                                float Vector1_20a623678efd46938e5f9485caef8e62;
                                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                float Vector1_f8515326c18542709304194130e489cf;
                                float Vector1_f8515326c18542709304194130e489cf_1;
                                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                CBUFFER_END

                                    // Object and Global properties
                                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                    TEXTURE2D(_SphereData);
                                    SAMPLER(sampler_SphereData);
                                    float4 _SphereData_TexelSize;
                                    TEXTURE2D(_BoxData);
                                    SAMPLER(sampler_BoxData);
                                    float4 _BoxData_TexelSize;
                                    TEXTURE2D(_ConeData);
                                    SAMPLER(sampler_ConeData);
                                    float4 _ConeData_TexelSize;
                                    float _NumSpheresActive;
                                    float _NumBoxesActive;
                                    float _NumConesActive;
                                    SAMPLER(SamplerState_Linear_Clamp);
                                    SAMPLER(SamplerState_Point_Clamp);

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

                                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                    {
                                        float3 WorldSpaceNormal;
                                        float3 WorldSpaceTangent;
                                        float3 WorldSpaceBiTangent;
                                        float3 ObjectSpacePosition;
                                        float3 WorldSpacePosition;
                                        float3 TimeParameters;
                                    };

                                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                    {
                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                    }

                                    void Unity_Subtract_float(float A, float B, out float Out)
                                    {
                                        Out = A - B;
                                    }

                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                    {
                                        Out = (T - A) / (B - A);
                                    }

                                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                    {
                                        float3 WorldSpacePosition;
                                    };

                                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                    {
                                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                    }

                                    // 596131a919f37b2a31c2db359d7db57a
                                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                    {
                                        float3 WorldSpacePosition;
                                    };

                                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                    {
                                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                    }

                                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                    {
                                        Out = Predicate ? True : False;
                                    }

                                    void Unity_Minimum_float(float A, float B, out float Out)
                                    {
                                        Out = min(A, B);
                                    };

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
                                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                        description.Normal = IN.ObjectSpaceNormal;
                                        description.Tangent = IN.ObjectSpaceTangent;
                                        return description;
                                    }

                                    // Graph Pixel
                                    struct SurfaceDescription
                                    {
                                        float Alpha;
                                        float AlphaClipThreshold;
                                    };

                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                    {
                                        SurfaceDescription surface = (SurfaceDescription)0;
                                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                        surface.AlphaClipThreshold = 0.01;
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
                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

                                    ENDHLSL
                                }
                                Pass
                                {
                                    Name "DepthNormals"
                                    Tags
                                    {
                                        "LightMode" = "DepthNormals"
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
                                        #define _AlphaClip 1
                                        #define _NORMALMAP 1
                                        #define _NORMAL_DROPOFF_TS 1
                                        #define ATTRIBUTES_NEED_NORMAL
                                        #define ATTRIBUTES_NEED_TANGENT
                                        #define ATTRIBUTES_NEED_TEXCOORD1
                                        #define VARYINGS_NEED_POSITION_WS
                                        #define VARYINGS_NEED_NORMAL_WS
                                        #define VARYINGS_NEED_TANGENT_WS
                                        #define FEATURES_GRAPH_VERTEX
                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
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
                                            float4 uv1 : TEXCOORD1;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            uint instanceID : INSTANCEID_SEMANTIC;
                                            #endif
                                        };
                                        struct Varyings
                                        {
                                            float4 positionCS : SV_POSITION;
                                            float3 positionWS;
                                            float3 normalWS;
                                            float4 tangentWS;
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
                                            float3 TangentSpaceNormal;
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
                                            float3 interp1 : TEXCOORD1;
                                            float4 interp2 : TEXCOORD2;
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
                                            output.interp1.xyz = input.normalWS;
                                            output.interp2.xyzw = input.tangentWS;
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
                                            output.normalWS = input.interp1.xyz;
                                            output.tangentWS = input.interp2.xyzw;
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
                                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                                        float Vector1_20a623678efd46938e5f9485caef8e62;
                                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                        float Vector1_f8515326c18542709304194130e489cf;
                                        float Vector1_f8515326c18542709304194130e489cf_1;
                                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                        CBUFFER_END

                                            // Object and Global properties
                                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                            TEXTURE2D(_SphereData);
                                            SAMPLER(sampler_SphereData);
                                            float4 _SphereData_TexelSize;
                                            TEXTURE2D(_BoxData);
                                            SAMPLER(sampler_BoxData);
                                            float4 _BoxData_TexelSize;
                                            TEXTURE2D(_ConeData);
                                            SAMPLER(sampler_ConeData);
                                            float4 _ConeData_TexelSize;
                                            float _NumSpheresActive;
                                            float _NumBoxesActive;
                                            float _NumConesActive;
                                            SAMPLER(SamplerState_Linear_Clamp);
                                            SAMPLER(SamplerState_Point_Clamp);

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

                                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                            {
                                                float3 WorldSpaceNormal;
                                                float3 WorldSpaceTangent;
                                                float3 WorldSpaceBiTangent;
                                                float3 ObjectSpacePosition;
                                                float3 WorldSpacePosition;
                                                float3 TimeParameters;
                                            };

                                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                            {
                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                            }

                                            void Unity_Subtract_float(float A, float B, out float Out)
                                            {
                                                Out = A - B;
                                            }

                                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                            {
                                                Out = (T - A) / (B - A);
                                            }

                                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                            {
                                                float3 WorldSpacePosition;
                                            };

                                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                            {
                                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                            }

                                            // 596131a919f37b2a31c2db359d7db57a
                                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                            {
                                                float3 WorldSpacePosition;
                                            };

                                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                            {
                                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                            }

                                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                            {
                                                Out = Predicate ? True : False;
                                            }

                                            void Unity_Minimum_float(float A, float B, out float Out)
                                            {
                                                Out = min(A, B);
                                            };

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
                                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                description.Normal = IN.ObjectSpaceNormal;
                                                description.Tangent = IN.ObjectSpaceTangent;
                                                return description;
                                            }

                                            // Graph Pixel
                                            struct SurfaceDescription
                                            {
                                                float3 NormalTS;
                                                float Alpha;
                                                float AlphaClipThreshold;
                                            };

                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                            {
                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                surface.NormalTS = IN.TangentSpaceNormal;
                                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                surface.AlphaClipThreshold = 0.01;
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



                                                output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


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
                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                                            ENDHLSL
                                        }
                                        Pass
                                        {
                                            Name "Meta"
                                            Tags
                                            {
                                                "LightMode" = "Meta"
                                            }

                                                // Render State
                                                Cull Off

                                                // Debug
                                                // <None>

                                                // --------------------------------------------------
                                                // Pass

                                                HLSLPROGRAM

                                                // Pragmas
                                                #pragma target 4.5
                                                #pragma exclude_renderers gles gles3 glcore
                                                #pragma vertex vert
                                                #pragma geometry geom
                                                #pragma fragment frag

                                                // DotsInstancingOptions: <None>
                                                // HybridV1InjectedBuiltinProperties: <None>

                                                // Keywords
                                                #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                                                // GraphKeywords: <None>

                                                // Defines
                                                #define _AlphaClip 1
                                                #define _NORMALMAP 1
                                                #define _NORMAL_DROPOFF_TS 1
                                                #define ATTRIBUTES_NEED_NORMAL
                                                #define ATTRIBUTES_NEED_TANGENT
                                                #define ATTRIBUTES_NEED_TEXCOORD1
                                                #define ATTRIBUTES_NEED_TEXCOORD2
                                                #define VARYINGS_NEED_POSITION_WS
                                                #define FEATURES_GRAPH_VERTEX
                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                #define SHADERPASS SHADERPASS_META
                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                                // Includes
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

                                                // --------------------------------------------------
                                                // Structs and Packing

                                                struct Attributes
                                                {
                                                    float3 positionOS : POSITION;
                                                    float3 normalOS : NORMAL;
                                                    float4 tangentOS : TANGENT;
                                                    float4 uv1 : TEXCOORD1;
                                                    float4 uv2 : TEXCOORD2;
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
                                                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                float Vector1_20a623678efd46938e5f9485caef8e62;
                                                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                float Vector1_f8515326c18542709304194130e489cf;
                                                float Vector1_f8515326c18542709304194130e489cf_1;
                                                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                CBUFFER_END

                                                    // Object and Global properties
                                                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                    TEXTURE2D(_SphereData);
                                                    SAMPLER(sampler_SphereData);
                                                    float4 _SphereData_TexelSize;
                                                    TEXTURE2D(_BoxData);
                                                    SAMPLER(sampler_BoxData);
                                                    float4 _BoxData_TexelSize;
                                                    TEXTURE2D(_ConeData);
                                                    SAMPLER(sampler_ConeData);
                                                    float4 _ConeData_TexelSize;
                                                    float _NumSpheresActive;
                                                    float _NumBoxesActive;
                                                    float _NumConesActive;
                                                    SAMPLER(SamplerState_Linear_Clamp);
                                                    SAMPLER(SamplerState_Point_Clamp);

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

                                                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                    {
                                                        float3 WorldSpaceNormal;
                                                        float3 WorldSpaceTangent;
                                                        float3 WorldSpaceBiTangent;
                                                        float3 ObjectSpacePosition;
                                                        float3 WorldSpacePosition;
                                                        float3 TimeParameters;
                                                    };

                                                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                    {
                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                    }

                                                    void Unity_Subtract_float(float A, float B, out float Out)
                                                    {
                                                        Out = A - B;
                                                    }

                                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                    {
                                                        Out = (T - A) / (B - A);
                                                    }

                                                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                    {
                                                        float3 WorldSpacePosition;
                                                    };

                                                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                    {
                                                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                    }

                                                    // 596131a919f37b2a31c2db359d7db57a
                                                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                    {
                                                        float3 WorldSpacePosition;
                                                    };

                                                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                    {
                                                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                    }

                                                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                    {
                                                        Out = Predicate ? True : False;
                                                    }

                                                    void Unity_Minimum_float(float A, float B, out float Out)
                                                    {
                                                        Out = min(A, B);
                                                    };

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
                                                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                        description.Normal = IN.ObjectSpaceNormal;
                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                        return description;
                                                    }

                                                    // Graph Pixel
                                                    struct SurfaceDescription
                                                    {
                                                        float3 BaseColor;
                                                        float3 Emission;
                                                        float Alpha;
                                                        float AlphaClipThreshold;
                                                    };

                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                    {
                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                        float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                                                        float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                        float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                                                        Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                                                        float4 _Property_d3a4c2b7db6047fab68359468da1873d_Out_0 = IsGammaSpace() ? LinearToSRGB(Color_7bf11e24f10942e9a75fc363b7f14b40) : Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                        surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                        surface.Emission = (_Property_d3a4c2b7db6047fab68359468da1873d_Out_0.xyz);
                                                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                        surface.AlphaClipThreshold = 0.01;
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
                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

                                                    ENDHLSL
                                                }
                                                Pass
                                                {
                                                        // Name: <None>
                                                        Tags
                                                        {
                                                            "LightMode" = "Universal2D"
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
                                                        #pragma vertex vert
                                                        #pragma geometry geom
                                                        #pragma fragment frag

                                                        // DotsInstancingOptions: <None>
                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                        // Keywords
                                                        // PassKeywords: <None>
                                                        // GraphKeywords: <None>

                                                        // Defines
                                                        #define _AlphaClip 1
                                                        #define _NORMALMAP 1
                                                        #define _NORMAL_DROPOFF_TS 1
                                                        #define ATTRIBUTES_NEED_NORMAL
                                                        #define ATTRIBUTES_NEED_TANGENT
                                                        #define VARYINGS_NEED_POSITION_WS
                                                        #define FEATURES_GRAPH_VERTEX
                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                        #define SHADERPASS SHADERPASS_2D
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
                                                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                        float Vector1_20a623678efd46938e5f9485caef8e62;
                                                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                        float Vector1_f8515326c18542709304194130e489cf;
                                                        float Vector1_f8515326c18542709304194130e489cf_1;
                                                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                        CBUFFER_END

                                                            // Object and Global properties
                                                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                            TEXTURE2D(_SphereData);
                                                            SAMPLER(sampler_SphereData);
                                                            float4 _SphereData_TexelSize;
                                                            TEXTURE2D(_BoxData);
                                                            SAMPLER(sampler_BoxData);
                                                            float4 _BoxData_TexelSize;
                                                            TEXTURE2D(_ConeData);
                                                            SAMPLER(sampler_ConeData);
                                                            float4 _ConeData_TexelSize;
                                                            float _NumSpheresActive;
                                                            float _NumBoxesActive;
                                                            float _NumConesActive;
                                                            SAMPLER(SamplerState_Linear_Clamp);
                                                            SAMPLER(SamplerState_Point_Clamp);

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

                                                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                            {
                                                                float3 WorldSpaceNormal;
                                                                float3 WorldSpaceTangent;
                                                                float3 WorldSpaceBiTangent;
                                                                float3 ObjectSpacePosition;
                                                                float3 WorldSpacePosition;
                                                                float3 TimeParameters;
                                                            };

                                                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                            {
                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                            }

                                                            void Unity_Subtract_float(float A, float B, out float Out)
                                                            {
                                                                Out = A - B;
                                                            }

                                                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                            {
                                                                Out = (T - A) / (B - A);
                                                            }

                                                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                            {
                                                                float3 WorldSpacePosition;
                                                            };

                                                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                            {
                                                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                            }

                                                            // 596131a919f37b2a31c2db359d7db57a
                                                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                            {
                                                                float3 WorldSpacePosition;
                                                            };

                                                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                            {
                                                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                            }

                                                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                            {
                                                                Out = Predicate ? True : False;
                                                            }

                                                            void Unity_Minimum_float(float A, float B, out float Out)
                                                            {
                                                                Out = min(A, B);
                                                            };

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
                                                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                return description;
                                                            }

                                                            // Graph Pixel
                                                            struct SurfaceDescription
                                                            {
                                                                float3 BaseColor;
                                                                float Alpha;
                                                                float AlphaClipThreshold;
                                                            };

                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                            {
                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                                                                float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                                                                Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                                                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                surface.AlphaClipThreshold = 0.01;
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
                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

                                                            ENDHLSL
                                                        }
    }
        SubShader
                                                            {
                                                                Tags
                                                                {
                                                                    "RenderPipeline" = "UniversalPipeline"
                                                                    "RenderType" = "Opaque"
                                                                    "UniversalMaterialType" = "Lit"
                                                                    "Queue" = "AlphaTest"
                                                                }
                                                                Pass
                                                                {
                                                                    Name "Universal Forward"
                                                                    Tags
                                                                    {
                                                                        "LightMode" = "UniversalForward"
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
                                                                #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
                                                                #pragma multi_compile _ LIGHTMAP_ON
                                                                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                                                                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                                                                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                                                                #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
                                                                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                                                                #pragma multi_compile _ _SHADOWS_SOFT
                                                                #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                                                                #pragma multi_compile _ SHADOWS_SHADOWMASK
                                                                // GraphKeywords: <None>

                                                                // Defines
                                                                #define _AlphaClip 1
                                                                #define _NORMALMAP 1
                                                                #define _NORMAL_DROPOFF_TS 1
                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                #define ATTRIBUTES_NEED_TEXCOORD1
                                                                #define VARYINGS_NEED_POSITION_WS
                                                                #define VARYINGS_NEED_NORMAL_WS
                                                                #define VARYINGS_NEED_TANGENT_WS
                                                                #define VARYINGS_NEED_VIEWDIRECTION_WS
                                                                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                                                                #define FEATURES_GRAPH_VERTEX
                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                #define SHADERPASS SHADERPASS_FORWARD
                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                                                // Includes
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

                                                                // --------------------------------------------------
                                                                // Structs and Packing

                                                                struct Attributes
                                                                {
                                                                    float3 positionOS : POSITION;
                                                                    float3 normalOS : NORMAL;
                                                                    float4 tangentOS : TANGENT;
                                                                    float4 uv1 : TEXCOORD1;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    uint instanceID : INSTANCEID_SEMANTIC;
                                                                    #endif
                                                                };
                                                                struct Varyings
                                                                {
                                                                    float4 positionCS : SV_POSITION;
                                                                    float3 positionWS;
                                                                    float3 normalWS;
                                                                    float4 tangentWS;
                                                                    float3 viewDirectionWS;
                                                                    #if defined(LIGHTMAP_ON)
                                                                    float2 lightmapUV;
                                                                    #endif
                                                                    #if !defined(LIGHTMAP_ON)
                                                                    float3 sh;
                                                                    #endif
                                                                    float4 fogFactorAndVertexLight;
                                                                    float4 shadowCoord;
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
                                                                    float3 TangentSpaceNormal;
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
                                                                    float3 interp1 : TEXCOORD1;
                                                                    float4 interp2 : TEXCOORD2;
                                                                    float3 interp3 : TEXCOORD3;
                                                                    #if defined(LIGHTMAP_ON)
                                                                    float2 interp4 : TEXCOORD4;
                                                                    #endif
                                                                    #if !defined(LIGHTMAP_ON)
                                                                    float3 interp5 : TEXCOORD5;
                                                                    #endif
                                                                    float4 interp6 : TEXCOORD6;
                                                                    float4 interp7 : TEXCOORD7;
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
                                                                    output.interp1.xyz = input.normalWS;
                                                                    output.interp2.xyzw = input.tangentWS;
                                                                    output.interp3.xyz = input.viewDirectionWS;
                                                                    #if defined(LIGHTMAP_ON)
                                                                    output.interp4.xy = input.lightmapUV;
                                                                    #endif
                                                                    #if !defined(LIGHTMAP_ON)
                                                                    output.interp5.xyz = input.sh;
                                                                    #endif
                                                                    output.interp6.xyzw = input.fogFactorAndVertexLight;
                                                                    output.interp7.xyzw = input.shadowCoord;
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
                                                                    output.normalWS = input.interp1.xyz;
                                                                    output.tangentWS = input.interp2.xyzw;
                                                                    output.viewDirectionWS = input.interp3.xyz;
                                                                    #if defined(LIGHTMAP_ON)
                                                                    output.lightmapUV = input.interp4.xy;
                                                                    #endif
                                                                    #if !defined(LIGHTMAP_ON)
                                                                    output.sh = input.interp5.xyz;
                                                                    #endif
                                                                    output.fogFactorAndVertexLight = input.interp6.xyzw;
                                                                    output.shadowCoord = input.interp7.xyzw;
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
                                                                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                float Vector1_f8515326c18542709304194130e489cf;
                                                                float Vector1_f8515326c18542709304194130e489cf_1;
                                                                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                CBUFFER_END

                                                                    // Object and Global properties
                                                                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                    TEXTURE2D(_SphereData);
                                                                    SAMPLER(sampler_SphereData);
                                                                    float4 _SphereData_TexelSize;
                                                                    TEXTURE2D(_BoxData);
                                                                    SAMPLER(sampler_BoxData);
                                                                    float4 _BoxData_TexelSize;
                                                                    TEXTURE2D(_ConeData);
                                                                    SAMPLER(sampler_ConeData);
                                                                    float4 _ConeData_TexelSize;
                                                                    float _NumSpheresActive;
                                                                    float _NumBoxesActive;
                                                                    float _NumConesActive;
                                                                    SAMPLER(SamplerState_Linear_Clamp);
                                                                    SAMPLER(SamplerState_Point_Clamp);

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

                                                                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                    {
                                                                        float3 WorldSpaceNormal;
                                                                        float3 WorldSpaceTangent;
                                                                        float3 WorldSpaceBiTangent;
                                                                        float3 ObjectSpacePosition;
                                                                        float3 WorldSpacePosition;
                                                                        float3 TimeParameters;
                                                                    };

                                                                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                    {
                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                    }

                                                                    void Unity_Subtract_float(float A, float B, out float Out)
                                                                    {
                                                                        Out = A - B;
                                                                    }

                                                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                    {
                                                                        Out = (T - A) / (B - A);
                                                                    }

                                                                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                    {
                                                                        float3 WorldSpacePosition;
                                                                    };

                                                                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                    {
                                                                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                    }

                                                                    // 596131a919f37b2a31c2db359d7db57a
                                                                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                    {
                                                                        float3 WorldSpacePosition;
                                                                    };

                                                                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                    {
                                                                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                    }

                                                                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                    {
                                                                        Out = Predicate ? True : False;
                                                                    }

                                                                    void Unity_Minimum_float(float A, float B, out float Out)
                                                                    {
                                                                        Out = min(A, B);
                                                                    };

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
                                                                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                        return description;
                                                                    }

                                                                    // Graph Pixel
                                                                    struct SurfaceDescription
                                                                    {
                                                                        float3 BaseColor;
                                                                        float3 NormalTS;
                                                                        float3 Emission;
                                                                        float Metallic;
                                                                        float Smoothness;
                                                                        float Occlusion;
                                                                        float Alpha;
                                                                        float AlphaClipThreshold;
                                                                    };

                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                    {
                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                        float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                                                                        float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                        float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                                                                        Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                                                                        float4 _Property_d3a4c2b7db6047fab68359468da1873d_Out_0 = IsGammaSpace() ? LinearToSRGB(Color_7bf11e24f10942e9a75fc363b7f14b40) : Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                        float _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0 = Vector1_f8515326c18542709304194130e489cf;
                                                                        float _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0 = Vector1_f8515326c18542709304194130e489cf_1;
                                                                        float _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0 = Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                        surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                        surface.NormalTS = IN.TangentSpaceNormal;
                                                                        surface.Emission = (_Property_d3a4c2b7db6047fab68359468da1873d_Out_0.xyz);
                                                                        surface.Metallic = _Property_5752a102880e4cfaa9df74730b85bb8d_Out_0;
                                                                        surface.Smoothness = _Property_a15c4dbe3c974add8c54f05014b8e2c4_Out_0;
                                                                        surface.Occlusion = _Property_5de19e9bfdb44b6da1fa282e0197694f_Out_0;
                                                                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                        surface.AlphaClipThreshold = 0.01;
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



                                                                        output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


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
                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

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
                                                                        #define _AlphaClip 1
                                                                        #define _NORMALMAP 1
                                                                        #define _NORMAL_DROPOFF_TS 1
                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                        #define VARYINGS_NEED_POSITION_WS
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
                                                                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                        float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                        float Vector1_f8515326c18542709304194130e489cf;
                                                                        float Vector1_f8515326c18542709304194130e489cf_1;
                                                                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                        CBUFFER_END

                                                                            // Object and Global properties
                                                                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                            TEXTURE2D(_SphereData);
                                                                            SAMPLER(sampler_SphereData);
                                                                            float4 _SphereData_TexelSize;
                                                                            TEXTURE2D(_BoxData);
                                                                            SAMPLER(sampler_BoxData);
                                                                            float4 _BoxData_TexelSize;
                                                                            TEXTURE2D(_ConeData);
                                                                            SAMPLER(sampler_ConeData);
                                                                            float4 _ConeData_TexelSize;
                                                                            float _NumSpheresActive;
                                                                            float _NumBoxesActive;
                                                                            float _NumConesActive;
                                                                            SAMPLER(SamplerState_Linear_Clamp);
                                                                            SAMPLER(SamplerState_Point_Clamp);

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

                                                                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                            {
                                                                                float3 WorldSpaceNormal;
                                                                                float3 WorldSpaceTangent;
                                                                                float3 WorldSpaceBiTangent;
                                                                                float3 ObjectSpacePosition;
                                                                                float3 WorldSpacePosition;
                                                                                float3 TimeParameters;
                                                                            };

                                                                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                            {
                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                            }

                                                                            void Unity_Subtract_float(float A, float B, out float Out)
                                                                            {
                                                                                Out = A - B;
                                                                            }

                                                                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                            {
                                                                                Out = (T - A) / (B - A);
                                                                            }

                                                                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                            {
                                                                                float3 WorldSpacePosition;
                                                                            };

                                                                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                            {
                                                                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                            }

                                                                            // 596131a919f37b2a31c2db359d7db57a
                                                                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                            {
                                                                                float3 WorldSpacePosition;
                                                                            };

                                                                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                            {
                                                                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                            }

                                                                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                            {
                                                                                Out = Predicate ? True : False;
                                                                            }

                                                                            void Unity_Minimum_float(float A, float B, out float Out)
                                                                            {
                                                                                Out = min(A, B);
                                                                            };

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
                                                                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                return description;
                                                                            }

                                                                            // Graph Pixel
                                                                            struct SurfaceDescription
                                                                            {
                                                                                float Alpha;
                                                                                float AlphaClipThreshold;
                                                                            };

                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                            {
                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                surface.AlphaClipThreshold = 0.01;
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
                                                                                #define _AlphaClip 1
                                                                                #define _NORMALMAP 1
                                                                                #define _NORMAL_DROPOFF_TS 1
                                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                                #define VARYINGS_NEED_POSITION_WS
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
                                                                                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                                float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                float Vector1_f8515326c18542709304194130e489cf;
                                                                                float Vector1_f8515326c18542709304194130e489cf_1;
                                                                                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                                CBUFFER_END

                                                                                    // Object and Global properties
                                                                                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                    TEXTURE2D(_SphereData);
                                                                                    SAMPLER(sampler_SphereData);
                                                                                    float4 _SphereData_TexelSize;
                                                                                    TEXTURE2D(_BoxData);
                                                                                    SAMPLER(sampler_BoxData);
                                                                                    float4 _BoxData_TexelSize;
                                                                                    TEXTURE2D(_ConeData);
                                                                                    SAMPLER(sampler_ConeData);
                                                                                    float4 _ConeData_TexelSize;
                                                                                    float _NumSpheresActive;
                                                                                    float _NumBoxesActive;
                                                                                    float _NumConesActive;
                                                                                    SAMPLER(SamplerState_Linear_Clamp);
                                                                                    SAMPLER(SamplerState_Point_Clamp);

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

                                                                                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                                    {
                                                                                        float3 WorldSpaceNormal;
                                                                                        float3 WorldSpaceTangent;
                                                                                        float3 WorldSpaceBiTangent;
                                                                                        float3 ObjectSpacePosition;
                                                                                        float3 WorldSpacePosition;
                                                                                        float3 TimeParameters;
                                                                                    };

                                                                                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                                    {
                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                                    }

                                                                                    void Unity_Subtract_float(float A, float B, out float Out)
                                                                                    {
                                                                                        Out = A - B;
                                                                                    }

                                                                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                                    {
                                                                                        Out = (T - A) / (B - A);
                                                                                    }

                                                                                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                                    {
                                                                                        float3 WorldSpacePosition;
                                                                                    };

                                                                                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                                    {
                                                                                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                                    }

                                                                                    // 596131a919f37b2a31c2db359d7db57a
                                                                                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                                    {
                                                                                        float3 WorldSpacePosition;
                                                                                    };

                                                                                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                                    {
                                                                                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                    }

                                                                                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                                    {
                                                                                        Out = Predicate ? True : False;
                                                                                    }

                                                                                    void Unity_Minimum_float(float A, float B, out float Out)
                                                                                    {
                                                                                        Out = min(A, B);
                                                                                    };

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
                                                                                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                                        return description;
                                                                                    }

                                                                                    // Graph Pixel
                                                                                    struct SurfaceDescription
                                                                                    {
                                                                                        float Alpha;
                                                                                        float AlphaClipThreshold;
                                                                                    };

                                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                    {
                                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                        surface.AlphaClipThreshold = 0.01;
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
                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

                                                                                    ENDHLSL
                                                                                }
                                                                                Pass
                                                                                {
                                                                                    Name "DepthNormals"
                                                                                    Tags
                                                                                    {
                                                                                        "LightMode" = "DepthNormals"
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
                                                                                        #pragma vertex vert
                                                                                        #pragma geometry geom
                                                                                        #pragma fragment frag

                                                                                        // DotsInstancingOptions: <None>
                                                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                                                        // Keywords
                                                                                        // PassKeywords: <None>
                                                                                        // GraphKeywords: <None>

                                                                                        // Defines
                                                                                        #define _AlphaClip 1
                                                                                        #define _NORMALMAP 1
                                                                                        #define _NORMAL_DROPOFF_TS 1
                                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                                        #define ATTRIBUTES_NEED_TEXCOORD1
                                                                                        #define VARYINGS_NEED_POSITION_WS
                                                                                        #define VARYINGS_NEED_NORMAL_WS
                                                                                        #define VARYINGS_NEED_TANGENT_WS
                                                                                        #define FEATURES_GRAPH_VERTEX
                                                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
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
                                                                                            float4 uv1 : TEXCOORD1;
                                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                                            uint instanceID : INSTANCEID_SEMANTIC;
                                                                                            #endif
                                                                                        };
                                                                                        struct Varyings
                                                                                        {
                                                                                            float4 positionCS : SV_POSITION;
                                                                                            float3 positionWS;
                                                                                            float3 normalWS;
                                                                                            float4 tangentWS;
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
                                                                                            float3 TangentSpaceNormal;
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
                                                                                            float3 interp1 : TEXCOORD1;
                                                                                            float4 interp2 : TEXCOORD2;
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
                                                                                            output.interp1.xyz = input.normalWS;
                                                                                            output.interp2.xyzw = input.tangentWS;
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
                                                                                            output.normalWS = input.interp1.xyz;
                                                                                            output.tangentWS = input.interp2.xyzw;
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
                                                                                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                        float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                        float Vector1_f8515326c18542709304194130e489cf;
                                                                                        float Vector1_f8515326c18542709304194130e489cf_1;
                                                                                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                                        CBUFFER_END

                                                                                            // Object and Global properties
                                                                                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                            TEXTURE2D(_SphereData);
                                                                                            SAMPLER(sampler_SphereData);
                                                                                            float4 _SphereData_TexelSize;
                                                                                            TEXTURE2D(_BoxData);
                                                                                            SAMPLER(sampler_BoxData);
                                                                                            float4 _BoxData_TexelSize;
                                                                                            TEXTURE2D(_ConeData);
                                                                                            SAMPLER(sampler_ConeData);
                                                                                            float4 _ConeData_TexelSize;
                                                                                            float _NumSpheresActive;
                                                                                            float _NumBoxesActive;
                                                                                            float _NumConesActive;
                                                                                            SAMPLER(SamplerState_Linear_Clamp);
                                                                                            SAMPLER(SamplerState_Point_Clamp);

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

                                                                                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                                            {
                                                                                                float3 WorldSpaceNormal;
                                                                                                float3 WorldSpaceTangent;
                                                                                                float3 WorldSpaceBiTangent;
                                                                                                float3 ObjectSpacePosition;
                                                                                                float3 WorldSpacePosition;
                                                                                                float3 TimeParameters;
                                                                                            };

                                                                                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                                            {
                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                                            }

                                                                                            void Unity_Subtract_float(float A, float B, out float Out)
                                                                                            {
                                                                                                Out = A - B;
                                                                                            }

                                                                                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                                            {
                                                                                                Out = (T - A) / (B - A);
                                                                                            }

                                                                                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                                            {
                                                                                                float3 WorldSpacePosition;
                                                                                            };

                                                                                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                                            {
                                                                                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                                            }

                                                                                            // 596131a919f37b2a31c2db359d7db57a
                                                                                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                                            {
                                                                                                float3 WorldSpacePosition;
                                                                                            };

                                                                                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                                            {
                                                                                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                            }

                                                                                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                                            {
                                                                                                Out = Predicate ? True : False;
                                                                                            }

                                                                                            void Unity_Minimum_float(float A, float B, out float Out)
                                                                                            {
                                                                                                Out = min(A, B);
                                                                                            };

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
                                                                                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                                return description;
                                                                                            }

                                                                                            // Graph Pixel
                                                                                            struct SurfaceDescription
                                                                                            {
                                                                                                float3 NormalTS;
                                                                                                float Alpha;
                                                                                                float AlphaClipThreshold;
                                                                                            };

                                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                            {
                                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                                                surface.NormalTS = IN.TangentSpaceNormal;
                                                                                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                surface.AlphaClipThreshold = 0.01;
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



                                                                                                output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);


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
                                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

                                                                                            ENDHLSL
                                                                                        }
                                                                                        Pass
                                                                                        {
                                                                                            Name "Meta"
                                                                                            Tags
                                                                                            {
                                                                                                "LightMode" = "Meta"
                                                                                            }

                                                                                                // Render State
                                                                                                Cull Off

                                                                                                // Debug
                                                                                                // <None>

                                                                                                // --------------------------------------------------
                                                                                                // Pass

                                                                                                HLSLPROGRAM

                                                                                                // Pragmas
                                                                                                #pragma target 2.0
                                                                                                #pragma only_renderers gles gles3 glcore
                                                                                                #pragma vertex vert
                                                                                                #pragma geometry geom
                                                                                                #pragma fragment frag

                                                                                                // DotsInstancingOptions: <None>
                                                                                                // HybridV1InjectedBuiltinProperties: <None>

                                                                                                // Keywords
                                                                                                #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
                                                                                                // GraphKeywords: <None>

                                                                                                // Defines
                                                                                                #define _AlphaClip 1
                                                                                                #define _NORMALMAP 1
                                                                                                #define _NORMAL_DROPOFF_TS 1
                                                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                                                #define ATTRIBUTES_NEED_TEXCOORD1
                                                                                                #define ATTRIBUTES_NEED_TEXCOORD2
                                                                                                #define VARYINGS_NEED_POSITION_WS
                                                                                                #define FEATURES_GRAPH_VERTEX
                                                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                                #define SHADERPASS SHADERPASS_META
                                                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

                                                                                                // Includes
                                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

                                                                                                // --------------------------------------------------
                                                                                                // Structs and Packing

                                                                                                struct Attributes
                                                                                                {
                                                                                                    float3 positionOS : POSITION;
                                                                                                    float3 normalOS : NORMAL;
                                                                                                    float4 tangentOS : TANGENT;
                                                                                                    float4 uv1 : TEXCOORD1;
                                                                                                    float4 uv2 : TEXCOORD2;
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
                                                                                                float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                                                float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                                float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                                float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                                float Vector1_f8515326c18542709304194130e489cf;
                                                                                                float Vector1_f8515326c18542709304194130e489cf_1;
                                                                                                float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                                                float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                                                CBUFFER_END

                                                                                                    // Object and Global properties
                                                                                                    TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                                    SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                                    TEXTURE2D(_SphereData);
                                                                                                    SAMPLER(sampler_SphereData);
                                                                                                    float4 _SphereData_TexelSize;
                                                                                                    TEXTURE2D(_BoxData);
                                                                                                    SAMPLER(sampler_BoxData);
                                                                                                    float4 _BoxData_TexelSize;
                                                                                                    TEXTURE2D(_ConeData);
                                                                                                    SAMPLER(sampler_ConeData);
                                                                                                    float4 _ConeData_TexelSize;
                                                                                                    float _NumSpheresActive;
                                                                                                    float _NumBoxesActive;
                                                                                                    float _NumConesActive;
                                                                                                    SAMPLER(SamplerState_Linear_Clamp);
                                                                                                    SAMPLER(SamplerState_Point_Clamp);

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

                                                                                                    struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                                                    {
                                                                                                        float3 WorldSpaceNormal;
                                                                                                        float3 WorldSpaceTangent;
                                                                                                        float3 WorldSpaceBiTangent;
                                                                                                        float3 ObjectSpacePosition;
                                                                                                        float3 WorldSpacePosition;
                                                                                                        float3 TimeParameters;
                                                                                                    };

                                                                                                    void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                                                    {
                                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                                                        float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                                                        float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                                                        float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                                                        Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                                                        float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                                                        float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                                                        float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                                                        Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                                                        float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                                                        Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                                                        float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                                                        Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                                                        float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                                                        float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                                                        Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                                                        float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                                                        Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                                                        float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                                                        float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                                                        Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                                                        float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                                                        Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                                                        float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                                                        float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                                                        float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                                                        Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                                                        float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                                                        VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                                                    }

                                                                                                    void Unity_Subtract_float(float A, float B, out float Out)
                                                                                                    {
                                                                                                        Out = A - B;
                                                                                                    }

                                                                                                    void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                                                    {
                                                                                                        Out = (T - A) / (B - A);
                                                                                                    }

                                                                                                    struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                                                    {
                                                                                                        float3 WorldSpacePosition;
                                                                                                    };

                                                                                                    void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                                                    {
                                                                                                        float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                        float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                                                        Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                                                        float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                                                        float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                                                        float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                                                        float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                                                        Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                                                        float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                                                        Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                                                        float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                                                        float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                                                        Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                                                    }

                                                                                                    // 596131a919f37b2a31c2db359d7db57a
                                                                                                    #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                                                    struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                                                    {
                                                                                                        float3 WorldSpacePosition;
                                                                                                    };

                                                                                                    void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                                                    {
                                                                                                        float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                                                        float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                                                        CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                                                        float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                                                        float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                                                        CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                                                        float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                                                        float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                                        CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                                                        isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                                    }

                                                                                                    void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                                                    {
                                                                                                        Out = Predicate ? True : False;
                                                                                                    }

                                                                                                    void Unity_Minimum_float(float A, float B, out float Out)
                                                                                                    {
                                                                                                        Out = min(A, B);
                                                                                                    };

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
                                                                                                        float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                                        float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                        float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                                        Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                        _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                                                        float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                        SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                                                        description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                                                        return description;
                                                                                                    }

                                                                                                    // Graph Pixel
                                                                                                    struct SurfaceDescription
                                                                                                    {
                                                                                                        float3 BaseColor;
                                                                                                        float3 Emission;
                                                                                                        float Alpha;
                                                                                                        float AlphaClipThreshold;
                                                                                                    };

                                                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                                    {
                                                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                                                        float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                        float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                                        Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                                                        _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                        float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                                                        SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                                                        float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                                                        float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                                                                                                        float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                                                        float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                                                                                                        Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                                                                                                        float4 _Property_d3a4c2b7db6047fab68359468da1873d_Out_0 = IsGammaSpace() ? LinearToSRGB(Color_7bf11e24f10942e9a75fc363b7f14b40) : Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                                                        float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                                                        float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                                                        float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                                                        Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                                                        _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                        float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                                                        SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                                                        float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                                                        Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                                                        float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                        Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                                                        surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                                                        surface.Emission = (_Property_d3a4c2b7db6047fab68359468da1873d_Out_0.xyz);
                                                                                                        surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                        surface.AlphaClipThreshold = 0.01;
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
                                                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

                                                                                                    ENDHLSL
                                                                                                }
                                                                                                Pass
                                                                                                {
                                                                                                        // Name: <None>
                                                                                                        Tags
                                                                                                        {
                                                                                                            "LightMode" = "Universal2D"
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
                                                                                                        #pragma vertex vert
                                                                                                        #pragma geometry geom
                                                                                                        #pragma fragment frag

                                                                                                        // DotsInstancingOptions: <None>
                                                                                                        // HybridV1InjectedBuiltinProperties: <None>

                                                                                                        // Keywords
                                                                                                        // PassKeywords: <None>
                                                                                                        // GraphKeywords: <None>

                                                                                                        // Defines
                                                                                                        #define _AlphaClip 1
                                                                                                        #define _NORMALMAP 1
                                                                                                        #define _NORMAL_DROPOFF_TS 1
                                                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                                                        #define VARYINGS_NEED_POSITION_WS
                                                                                                        #define FEATURES_GRAPH_VERTEX
                                                                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                                                        #define SHADERPASS SHADERPASS_2D
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
                                                                                                        float4 Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize;
                                                                                                        float Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                                        float Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                        float Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                                        float Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                                        float Vector1_f8515326c18542709304194130e489cf;
                                                                                                        float Vector1_f8515326c18542709304194130e489cf_1;
                                                                                                        float Vector1_ae2046b7e5204627939c74ee8ff49687;
                                                                                                        float4 Color_7bf11e24f10942e9a75fc363b7f14b40;
                                                                                                        CBUFFER_END

                                                                                                            // Object and Global properties
                                                                                                            TEXTURE2D(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                                            SAMPLER(samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194);
                                                                                                            TEXTURE2D(_SphereData);
                                                                                                            SAMPLER(sampler_SphereData);
                                                                                                            float4 _SphereData_TexelSize;
                                                                                                            TEXTURE2D(_BoxData);
                                                                                                            SAMPLER(sampler_BoxData);
                                                                                                            float4 _BoxData_TexelSize;
                                                                                                            TEXTURE2D(_ConeData);
                                                                                                            SAMPLER(sampler_ConeData);
                                                                                                            float4 _ConeData_TexelSize;
                                                                                                            float _NumSpheresActive;
                                                                                                            float _NumBoxesActive;
                                                                                                            float _NumConesActive;
                                                                                                            SAMPLER(SamplerState_Linear_Clamp);
                                                                                                            SAMPLER(SamplerState_Point_Clamp);

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

                                                                                                            struct Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec
                                                                                                            {
                                                                                                                float3 WorldSpaceNormal;
                                                                                                                float3 WorldSpaceTangent;
                                                                                                                float3 WorldSpaceBiTangent;
                                                                                                                float3 ObjectSpacePosition;
                                                                                                                float3 WorldSpacePosition;
                                                                                                                float3 TimeParameters;
                                                                                                            };

                                                                                                            void SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(float Vector1_2ade3a3830644d809de4a4ee466a849a, float Vector1_1c87ff25598349fbb8e54234c8989d36, float Vector1_b61d825e991e46df8616a320c7274c96, Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec IN, out float3 VertPos_OS_1)
                                                                                                            {
                                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1 = IN.WorldSpacePosition[0];
                                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2 = IN.WorldSpacePosition[1];
                                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3 = IN.WorldSpacePosition[2];
                                                                                                                float _Split_1cf5efa6971d4fd68c7b06a5dda26927_A_4 = 0;
                                                                                                                float _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0 = Vector1_2ade3a3830644d809de4a4ee466a849a;
                                                                                                                float _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2;
                                                                                                                Unity_Multiply_float(IN.TimeParameters.x, _Property_a7308c0c338942baae5c4fce9d5559c7_Out_0, _Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2);
                                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1 = IN.ObjectSpacePosition[0];
                                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_G_2 = IN.ObjectSpacePosition[1];
                                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3 = IN.ObjectSpacePosition[2];
                                                                                                                float _Split_96b1d9eaf50a4bb79c115d018518cbc4_A_4 = 0;
                                                                                                                float _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2;
                                                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Split_96b1d9eaf50a4bb79c115d018518cbc4_R_1, _Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2);
                                                                                                                float _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2;
                                                                                                                Unity_Multiply_float(_Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Split_96b1d9eaf50a4bb79c115d018518cbc4_B_3, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2);
                                                                                                                float _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2;
                                                                                                                Unity_Add_float(_Multiply_9a7122dd86ab419da7261e1218766bc5_Out_2, _Multiply_aa8f0b2dd6894669bfffa9dd78659f53_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2);
                                                                                                                float _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2;
                                                                                                                Unity_Add_float(_Multiply_e21951f8d59544a4ad68ed4b251b5af5_Out_2, _Add_9599e98b030a4362a4b911b3631bf2bc_Out_2, _Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2);
                                                                                                                float _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0 = Vector1_b61d825e991e46df8616a320c7274c96;
                                                                                                                float _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2;
                                                                                                                Unity_Multiply_float(_Add_a3768f7f5fcc40b4a03bcbd6e197f4d5_Out_2, _Property_a3d097d5c7d9423ebc2ec5c8e516eafa_Out_0, _Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2);
                                                                                                                float _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1;
                                                                                                                Unity_Sine_float(_Multiply_3b664338ff024e4c8760cb7bc6cb5ca4_Out_2, _Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1);
                                                                                                                float _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0 = Vector1_1c87ff25598349fbb8e54234c8989d36;
                                                                                                                float _Multiply_04f82800623f46ff89595df678dcbd71_Out_2;
                                                                                                                Unity_Multiply_float(_Sine_7cf97b673c6c4c328823b16cafbee0df_Out_1, _Property_186c5b4b5ccc4fc6968da54a24cfe886_Out_0, _Multiply_04f82800623f46ff89595df678dcbd71_Out_2);
                                                                                                                float _Add_9714632c5d854ee093f20a82907b696c_Out_2;
                                                                                                                Unity_Add_float(_Multiply_04f82800623f46ff89595df678dcbd71_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_G_2, _Add_9714632c5d854ee093f20a82907b696c_Out_2);
                                                                                                                float4 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4;
                                                                                                                float3 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5;
                                                                                                                float2 _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6;
                                                                                                                Unity_Combine_float(_Split_1cf5efa6971d4fd68c7b06a5dda26927_R_1, _Add_9714632c5d854ee093f20a82907b696c_Out_2, _Split_1cf5efa6971d4fd68c7b06a5dda26927_B_3, 0, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGBA_4, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5, _Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RG_6);
                                                                                                                float3 _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1 = TransformWorldToObject(_Combine_04c38b3683fc43a1bc13ab9a0b7f4f44_RGB_5.xyz);
                                                                                                                VertPos_OS_1 = _Transform_8d6b4fcf8ccb488d9340443cc80de3d1_Out_1;
                                                                                                            }

                                                                                                            void Unity_Subtract_float(float A, float B, out float Out)
                                                                                                            {
                                                                                                                Out = A - B;
                                                                                                            }

                                                                                                            void Unity_InverseLerp_float(float A, float B, float T, out float Out)
                                                                                                            {
                                                                                                                Out = (T - A) / (B - A);
                                                                                                            }

                                                                                                            struct Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601
                                                                                                            {
                                                                                                                float3 WorldSpacePosition;
                                                                                                            };

                                                                                                            void SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_PARAM(Texture2D_65dedb14781d455f8e7111ba2c60e22a, samplerTexture2D_65dedb14781d455f8e7111ba2c60e22a), float4 Texture2D_65dedb14781d455f8e7111ba2c60e22a_TexelSize, float Vector1_7e9815b630e3402bba3ad8dad155cb26, float Vector1_c66dcbd517744e8481d9b79c1b2a45eb, Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 IN, out float4 Colour_1)
                                                                                                            {
                                                                                                                float _Property_ce230e0c590f4d459ff79982c779b20c_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                                float _Multiply_c8b596ed39f14e24825673abc7562086_Out_2;
                                                                                                                Unity_Multiply_float(_Property_ce230e0c590f4d459ff79982c779b20c_Out_0, -1, _Multiply_c8b596ed39f14e24825673abc7562086_Out_2);
                                                                                                                float _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0 = Vector1_7e9815b630e3402bba3ad8dad155cb26;
                                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_R_1 = IN.WorldSpacePosition[0];
                                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_G_2 = IN.WorldSpacePosition[1];
                                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_B_3 = IN.WorldSpacePosition[2];
                                                                                                                float _Split_0668dd88f335466aaa2456f7c0287201_A_4 = 0;
                                                                                                                float _Property_d9716cee7d264164a9b84254748ea78e_Out_0 = Vector1_c66dcbd517744e8481d9b79c1b2a45eb;
                                                                                                                float _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2;
                                                                                                                Unity_Subtract_float(_Split_0668dd88f335466aaa2456f7c0287201_G_2, _Property_d9716cee7d264164a9b84254748ea78e_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2);
                                                                                                                float _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3;
                                                                                                                Unity_InverseLerp_float(_Multiply_c8b596ed39f14e24825673abc7562086_Out_2, _Property_985e5a5ed4b0484d83313e9aba7cd617_Out_0, _Subtract_9942f3c0fbfa4ea5866e078e11410929_Out_2, _InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3);
                                                                                                                float4 _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0 = SAMPLE_TEXTURE2D(Texture2D_65dedb14781d455f8e7111ba2c60e22a, SamplerState_Linear_Clamp, (_InverseLerp_1333e3ec8f4343399b99922b64267ced_Out_3.xx));
                                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_R_4 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.r;
                                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_G_5 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.g;
                                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_B_6 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.b;
                                                                                                                float _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_A_7 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0.a;
                                                                                                                Colour_1 = _SampleTexture2D_a51d7fdc8237437ea561637a90daeac5_RGBA_0;
                                                                                                            }

                                                                                                            // 596131a919f37b2a31c2db359d7db57a
                                                                                                            #include "Assets/Studio Assets/Shaders/HLSL Functions/VolumeClipFunctions.hlsl"

                                                                                                            struct Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d
                                                                                                            {
                                                                                                                float3 WorldSpacePosition;
                                                                                                            };

                                                                                                            void SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_PARAM(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, samplerTexture2D_699b0a21705f4815a2d8bc4558c6adb6), float4 Texture2D_699b0a21705f4815a2d8bc4558c6adb6_TexelSize, float Vector1_a8b8405353da46e6a93346e2b5a3160e, TEXTURE2D_PARAM(Texture2D_019505ca4cdc4a6594e7e00a33d32c66, samplerTexture2D_019505ca4cdc4a6594e7e00a33d32c66), float4 Texture2D_019505ca4cdc4a6594e7e00a33d32c66_TexelSize, float Vector1_90c0940ceabf4c8799f6ad69b535753f, TEXTURE2D_PARAM(Texture2D_95e6325cd9d547968f08cbc769c6b5dc, samplerTexture2D_95e6325cd9d547968f08cbc769c6b5dc), float4 Texture2D_95e6325cd9d547968f08cbc769c6b5dc_TexelSize, float Vector1_d0a490bcfc9e4d69af09965abff7de12, Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d IN, out float isInVolume_1)
                                                                                                            {
                                                                                                                float _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0 = Vector1_a8b8405353da46e6a93346e2b5a3160e;
                                                                                                                float _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2;
                                                                                                                CheckAgainstSpheres_float(Texture2D_699b0a21705f4815a2d8bc4558c6adb6, SamplerState_Point_Clamp, _Property_5c5a5974c5ea423e85ff2cd770299bbb_Out_0, IN.WorldSpacePosition, _CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2);
                                                                                                                float _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0 = Vector1_90c0940ceabf4c8799f6ad69b535753f;
                                                                                                                float _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5;
                                                                                                                CheckAgainstBoxes_float(_CustomFunction_8f165a95b3dd4fa4b18b5a4951777c4a_insideVolume_2, Texture2D_019505ca4cdc4a6594e7e00a33d32c66, SamplerState_Point_Clamp, _Property_2607c22a7fec40ce962c4b43893ec2c5_Out_0, IN.WorldSpacePosition, _CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5);
                                                                                                                float _Property_befe5711f57148fe9f101402cd15b4fb_Out_0 = Vector1_d0a490bcfc9e4d69af09965abff7de12;
                                                                                                                float _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                                                CheckAgainstCones_float(_CustomFunction_c8b3601f52404174b174d3a02c25e134_insideVolume_5, Texture2D_95e6325cd9d547968f08cbc769c6b5dc, SamplerState_Point_Clamp, _Property_befe5711f57148fe9f101402cd15b4fb_Out_0, IN.WorldSpacePosition, _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5);
                                                                                                                isInVolume_1 = _CustomFunction_4ba83dba57b646c8ab2bebc23f6aec3a_insideVolume_5;
                                                                                                            }

                                                                                                            void Unity_Branch_float(float Predicate, float True, float False, out float Out)
                                                                                                            {
                                                                                                                Out = Predicate ? True : False;
                                                                                                            }

                                                                                                            void Unity_Minimum_float(float A, float B, out float Out)
                                                                                                            {
                                                                                                                Out = min(A, B);
                                                                                                            };

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
                                                                                                                float _Property_bfdedf082a9d48228e418971744face5_Out_0 = Vector1_20316dd03bb141e5a52680117f6e4994;
                                                                                                                float _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                                float _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0 = Vector1_339876ac601549b7a0c475d8fc6c4dde;
                                                                                                                Bindings_RippleEffect_012ecc6f30b358b40b42635853eebdec _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceNormal = IN.WorldSpaceNormal;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceTangent = IN.WorldSpaceTangent;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpaceBiTangent = IN.WorldSpaceBiTangent;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.ObjectSpacePosition = IN.ObjectSpacePosition;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                                _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c.TimeParameters = IN.TimeParameters;
                                                                                                                float3 _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                                SG_RippleEffect_012ecc6f30b358b40b42635853eebdec(_Property_bfdedf082a9d48228e418971744face5_Out_0, _Property_8a1ac542cce34f34ae5927c0fec0c25b_Out_0, _Property_405546e54f4f442d9a2c18dbaefc73a7_Out_0, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c, _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1);
                                                                                                                description.Position = _RippleEffect_8ad3cbf3582a422ebcd9f18ee563481c_VertPosOS_1;
                                                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                                                return description;
                                                                                                            }

                                                                                                            // Graph Pixel
                                                                                                            struct SurfaceDescription
                                                                                                            {
                                                                                                                float3 BaseColor;
                                                                                                                float Alpha;
                                                                                                                float AlphaClipThreshold;
                                                                                                            };

                                                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                                                            {
                                                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                                                float _Property_f1907b2c71f543d9bab082664dd55c79_Out_0 = Vector1_20a623678efd46938e5f9485caef8e62;
                                                                                                                float _Property_55de1d0453a64385baea5814ee1866d6_Out_0 = Vector1_949be71b581b4ff8a0ea7c2828a0774e;
                                                                                                                Bindings_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601 _wsHeightGradient_bfb126ce7daf437899646852a140a901;
                                                                                                                _wsHeightGradient_bfb126ce7daf437899646852a140a901.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                                float4 _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1;
                                                                                                                SG_wsHeightGradient_aa5b8e3f2c1c96747ae8661257668601(TEXTURE2D_ARGS(Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194, samplerTexture2D_fbf9a40a647e41b095f3e0f8b4f7a194), Texture2D_fbf9a40a647e41b095f3e0f8b4f7a194_TexelSize, _Property_f1907b2c71f543d9bab082664dd55c79_Out_0, _Property_55de1d0453a64385baea5814ee1866d6_Out_0, _wsHeightGradient_bfb126ce7daf437899646852a140a901, _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1);
                                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_R_1 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[0];
                                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[1];
                                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[2];
                                                                                                                float _Split_b9d16acf50f14496a99bc1a9d3a32010_A_4 = _wsHeightGradient_bfb126ce7daf437899646852a140a901_Colour_1[3];
                                                                                                                float4 _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4;
                                                                                                                float3 _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                                                                float2 _Combine_2f17698545b44e2182d73c198e4d9018_RG_6;
                                                                                                                Unity_Combine_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_R_1, _Split_b9d16acf50f14496a99bc1a9d3a32010_G_2, _Split_b9d16acf50f14496a99bc1a9d3a32010_B_3, 0, _Combine_2f17698545b44e2182d73c198e4d9018_RGBA_4, _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5, _Combine_2f17698545b44e2182d73c198e4d9018_RG_6);
                                                                                                                float _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0 = _NumSpheresActive;
                                                                                                                float _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0 = _NumBoxesActive;
                                                                                                                float _Property_73a1b21e91bd450db7b334a994fdf351_Out_0 = _NumConesActive;
                                                                                                                Bindings_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d _VolumeClipping_72b7f5d7b08242548be321cd7eff727c;
                                                                                                                _VolumeClipping_72b7f5d7b08242548be321cd7eff727c.WorldSpacePosition = IN.WorldSpacePosition;
                                                                                                                float _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1;
                                                                                                                SG_VolumeClipping_333efe1c2e75c53439325bbbb0439b5d(TEXTURE2D_ARGS(_SphereData, sampler_SphereData), _SphereData_TexelSize, _Property_f57b1e1e06dc4adebad195dc4b2e9112_Out_0, TEXTURE2D_ARGS(_BoxData, sampler_BoxData), _BoxData_TexelSize, _Property_fdb77fa1118b428e8fbed885f4d1e21b_Out_0, TEXTURE2D_ARGS(_ConeData, sampler_ConeData), _ConeData_TexelSize, _Property_73a1b21e91bd450db7b334a994fdf351_Out_0, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c, _VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1);
                                                                                                                float _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3;
                                                                                                                Unity_Branch_float(_VolumeClipping_72b7f5d7b08242548be321cd7eff727c_isInVolume_1, 1, 0, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3);
                                                                                                                float _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                                Unity_Minimum_float(_Split_b9d16acf50f14496a99bc1a9d3a32010_A_4, _Branch_7788d07559c54a5990da0f07df7abdf8_Out_3, _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2);
                                                                                                                surface.BaseColor = _Combine_2f17698545b44e2182d73c198e4d9018_RGB_5;
                                                                                                                surface.Alpha = _Minimum_b9276b08482741efbaf8bb1d2a67015e_Out_2;
                                                                                                                surface.AlphaClipThreshold = 0.01;
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
                                                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

                                                                                                            ENDHLSL
                                                                                                        }
                                                            }
                                                                CustomEditor "ShaderGraph.PBRMasterGUI"
                                                                                                                FallBack "Hidden/Shader Graph/FallbackError"
}
