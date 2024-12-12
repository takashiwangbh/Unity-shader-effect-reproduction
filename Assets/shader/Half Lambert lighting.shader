Shader "Unity Shaders Book/Chapter 6/Half Lambert" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1) // 定义材质的漫反射颜色
    }
    SubShader {
        Pass { 
            Tags { "LightMode"="ForwardBase" } // 指定渲染模式为前向光照

            CGPROGRAM

            #pragma vertex vert       // 顶点着色器入口函数
            #pragma fragment frag     // 片段着色器入口函数

            #include "Lighting.cginc" // 引入 Unity 光照计算的库文件
                                                                                                                                                                                                                                                                                                                                
            fixed4 _Diffuse;          // 漫反射颜色变量

            // 顶点着色器输入结构
            struct a2v {
                float4 vertex : POSITION; // 顶点位置，物体空间
                float3 normal : NORMAL;   // 顶点法线，物体空间
            };

            // 顶点着色器输出结构
            struct v2f {
                float4 pos : SV_POSITION;     // 顶点的裁剪空间位置，用于光栅化
                float3 worldNormal : TEXCOORD0; // 顶点法线，传递到片段着色器
            };

            // 顶点着色器函数
            v2f vert(a2v v) {
                v2f o;

                // 将顶点从物体空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将法线从物体空间转换到世界空间
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

                return o;
            }

            // 片段着色器函数
            fixed4 frag(v2f i) : SV_Target {
                // 获取环境光分量，表示基础光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 将传入的法线向量归一化
                fixed3 worldNormal = normalize(i.worldNormal);

                // 获取光源方向向量（世界空间），并归一化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算 Half Lambert 光照系数
                fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;

                // 计算漫反射光分量
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

                // 合成环境光和漫反射光
                fixed3 color = ambient + diffuse;

                // 返回颜色值，并设置不透明度为 1
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    } 
    // 回退到 Unity 的 Diffuse Shader，如果设备不支持当前 Shader
    FallBack "Diffuse"
}
