#ifndef POI_VERT
    #define POI_VERT

    float _EnableFakeArm;
    float _BoneLength;
    float _ExtraForearmLength;
    float _ExtraGrabRatio;
    float _ShaderIKTargetLightIntensity;
    float _VertexScale;
    int _IsLeftArm;
    
    uint vertexManipulationUV;

    #include "../../../HaiHandholdingShaderIK/HaiHandholdingShaderIK.cginc"
    
    void ComputeVertexLightColor(inout v2f i)
    {
        #if defined(VERTEXLIGHT_ON)
            i.vertexLightColor = Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, i.worldPos, i.normal
            );
        #endif
    }
    
    v2f vert(appdata v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        v2f o;
        
        applyLocalVertexTransformation(v.normal, v.tangent, v.vertex);
        
        #ifdef POI_META_PASS
            v.vertex.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
            v.vertex.z = v.vertex.z > 0 ? 0.0001: 0;
        #endif
        
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        if (_EnableFakeArm > 0.5)
        {
            v.vertex = transformArm(
                float4(v.vertex.xyz * _VertexScale, 1),
                v.color,
                _ShaderIKTargetLightIntensity,
                true,
                float4(0.001, (isLeftArm ? -1 : 1) * -0.002, -0.003, 1) + float4(
                    sin(_Time.y * 0.3) * 0.00002,
                    sin(_Time.y * 0.43) * 0.000035,
                    sin(_Time.y * 1.24) * 0.00015, 0),
                _BoneLength / 1000000,
                (_BoneLength + _ExtraForearmLength) / 1000000,
                (_BoneLength * _ExtraGrabRatio + _ExtraForearmLength) / 1000000,
                isLeftArm
            );
        }
        else
        {
            v.vertex = float4(0, 0, 0, 0);
        }
        
        #ifdef _REQUIRE_UV2 //POI_MIRROR
            applyMirrorRenderVert(v.vertex);
        #endif
        
        TANGENT_SPACE_ROTATION;
        o.localPos = v.vertex;
        o.worldPos = mul(unity_ObjectToWorld, o.localPos);
        o.normal = UnityObjectToWorldNormal(v.normal);
        //o.localPos.x *= -1;
        //o.localPos.xz += sin(o.localPos.y * 100 + _Time.y * 5) * .0025;
        
        float2 uvToUse;
        UNITY_BRANCH
        if (vertexManipulationUV == 0)
        {
            uvToUse = v.uv0.xy;
        }
        UNITY_BRANCH
        if(vertexManipulationUV == 1)
        {
            uvToUse = v.uv1.xy;
        }
        UNITY_BRANCH
        if(vertexManipulationUV == 2)
        {
            uvToUse = v.uv2.xy;
        }
        UNITY_BRANCH
        if(vertexManipulationUV == 3)
        {
            uvToUse = v.uv3.xy;
        }
        
        applyWorldVertexTransformation(o.worldPos, o.localPos, o.normal, uvToUse);
        o.pos = UnityObjectToClipPos(o.localPos);
        o.grabPos = ComputeGrabScreenPos(o.pos);
        o.uv0.xy = v.uv0.xy;
        o.uv0.zw = v.uv1.xy;
        o.uv1.xy = v.uv2.xy;
        o.uv1.zw = v.uv3.xy;
        o.vertexColor = v.color;
        o.modelPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
        o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
        
        #ifdef POI_BULGE
            bulgyWolgy(o);
        #endif
        
        #if defined(GRAIN)
            o.screenPos = ComputeScreenPos(o.pos);
        #endif
        
        o.angleAlpha = 1;
        #ifdef _SUNDISK_NONE //POI_RANDOM
            o.angleAlpha = ApplyAngleBasedRendering(o.modelPos, o.worldPos);
        #endif
        
        #if defined(LIGHTMAP_ON)
            o.lightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        #endif
        #ifdef DYNAMICLIGHTMAP_ON
            o.lightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif
        
        UNITY_TRANSFER_SHADOW(o, o.uv0.xy);
        UNITY_TRANSFER_FOG(o, o.pos);
        ComputeVertexLightColor(o);
        
        #if defined(_PARALLAXMAP) // POI_PARALLAX
            v.tangent.xyz = normalize(v.tangent.xyz);
            v.normal = normalize(v.normal);
            float3x3 objectToTangent = float3x3(
                v.tangent.xyz,
                cross(v.normal, v.tangent.xyz) * v.tangent.w,
                v.normal
            );
            o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
        #endif
        
        return o;
    }
#endif