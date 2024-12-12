Shader "Unity Shaders Book/Chapter 9/Attenuation And Shadow Use Build-in Functions" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1) // 漫反射颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1) // 高光颜色
        _Gloss ("Gloss", Range(8.0, 256)) = 20 // 高光光滑度，值越高光越集中
    }
    SubShader {
        Tags { "RenderType"="Opaque" } // 定义渲染类型为不透明

        Pass {
            // 第一层 Pass：处理环境光和第一个像素光源（通常是方向光）
            Tags { "LightMode"="ForwardBase" } // 前向渲染基础模式

            CGPROGRAM

            #pragma multi_compile_fwdbase // 支持多种前向渲染模式（基础光照）
            #pragma vertex vert           // 指定顶点着色器函数
            #pragma fragment frag         // 指定片段着色器函数

            #include "Lighting.cginc"     // 包含内置光照相关宏
            #include "AutoLight.cginc"   // 包含自动光照和阴影宏

            fixed4 _Diffuse; // 漫反射颜色
            fixed4 _Specular; // 高光颜色
            float _Gloss; // 高光光滑度

            struct a2v {
                float4 vertex : POSITION; // 输入顶点位置
                float3 normal : NORMAL;   // 输入顶点法线
            };

            struct v2f {
                float4 pos : SV_POSITION;         // 裁剪空间位置，用于屏幕投影
                float3 worldNormal : TEXCOORD0;  // 世界空间法线
                float3 worldPos : TEXCOORD1;     // 世界空间位置
                SHADOW_COORDS(2)                 // 阴影坐标
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 将物体空间顶点转换为裁剪空间

                o.worldNormal = UnityObjectToWorldNormal(v.normal); // 将法线转换为世界空间

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 计算世界空间顶点位置

                TRANSFER_SHADOW(o); // 传递阴影信息到片段着色器

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal); // 归一化法线
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); // 计算光源方向

                // 计算环境光贡献
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射贡献（Lambert 光照模型）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // 计算高光贡献（Blinn-Phong 模型）
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); // 观察方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);           // 半向量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 计算光衰减和阴影信息
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 返回最终颜色：环境光 + 漫反射 + 高光，乘以光衰减
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }

        Pass {
            // 第二层 Pass：处理附加像素光源（例如点光源和聚光灯）
            Tags { "LightMode"="ForwardAdd" } // 前向渲染附加光源模式

            Blend One One // 添加光源颜色混合模式

            CGPROGRAM

            #pragma multi_compile_fwdadd // 支持多种前向渲染模式（附加光源）
            #pragma vertex vert          // 指定顶点着色器函数
            #pragma fragment frag        // 指定片段着色器函数

            #include "Lighting.cginc"    // 包含内置光照相关宏
            #include "AutoLight.cginc"  // 包含自动光照和阴影宏

            fixed4 _Diffuse; // 漫反射颜色
            fixed4 _Specular; // 高光颜色
            float _Gloss; // 高光光滑度

            struct a2v {
                float4 vertex : POSITION; // 输入顶点位置
                float3 normal : NORMAL;   // 输入顶点法线
            };

            struct v2f {
                float4 pos : SV_POSITION;         // 裁剪空间位置，用于屏幕投影
                float3 worldNormal : TEXCOORD0;  // 世界空间法线
                float3 worldPos : TEXCOORD1;     // 世界空间位置
                SHADOW_COORDS(2)                 // 阴影坐标
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 将物体空间顶点转换为裁剪空间

                o.worldNormal = UnityObjectToWorldNormal(v.normal); // 将法线转换为世界空间

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 计算世界空间顶点位置

                TRANSFER_SHADOW(o); // 传递阴影信息到片段着色器

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal); // 归一化法线
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); // 计算光源方向

                // 计算漫反射贡献
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // 计算高光贡献
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); // 观察方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);           // 半向量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 计算光衰减和阴影信息
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 返回最终颜色：漫反射 + 高光，乘以光衰减
                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular" // 如果当前 GPU 不支持该 Shader，使用内置的 Specular Shader
}
