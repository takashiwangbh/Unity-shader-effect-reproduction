Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)   // 定义材质的漫反射颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1) // 定义材质的镜面反射颜色
        _Gloss ("Gloss", Range(8.0, 256)) = 20      // 定义材质的光泽度（高光锐度）
    }
    SubShader {
        Pass { 
            Tags { "LightMode"="ForwardBase" } // 指定渲染模式为前向光照

            CGPROGRAM
            
            #pragma vertex vert       // 顶点着色器入口
            #pragma fragment frag     // 片段着色器入口

            #include "Lighting.cginc" // 引入 Unity 光照计算的库文件

            fixed4 _Diffuse;          // 漫反射颜色
            fixed4 _Specular;         // 镜面反射颜色
            float _Gloss;             // 高光光泽度

            // 顶点着色器输入结构
            struct a2v {
                float4 vertex : POSITION; // 顶点位置（物体空间）
                float3 normal : NORMAL;   // 顶点法线（物体空间）
            };

            // 顶点着色器输出结构
            struct v2f {
                float4 pos : SV_POSITION; // 顶点裁剪空间位置，用于光栅化
                fixed3 color : COLOR;     // 顶点颜色，传递到片段着色器
            };

            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;

                // 将顶点从物体空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获取环境光分量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 将法线从物体空间转换到世界空间并归一化
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                // 获取光源方向并归一化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射光分量
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 计算反射光方向（世界空间）
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));

                // 获取视线方向（从物体到摄像机方向，世界空间）
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

                // 计算镜面反射光分量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                // 合成环境光、漫反射光和镜面反射光
                o.color = ambient + diffuse + specular;

                return o;
            }

            // 片段着色器
            fixed4 frag(v2f i) : SV_Target {
                // 直接输出顶点着色器计算的颜色
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    } 
    FallBack "Specular" // 如果当前设备不支持该 Shader，回退到 Unity 内置的 Specular Shader
}
