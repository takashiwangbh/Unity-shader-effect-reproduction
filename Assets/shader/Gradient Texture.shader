Shader "Unity Shaders Book/Chapter 7/Ramp Texture" {
    Properties {
        // 定义用于调整的属性，允许用户在 Unity 编辑器中修改这些值
        _Color ("Color Tint", Color) = (1, 1, 1, 1) // 主纹理的颜色叠加
        _RampTex ("Ramp Tex", 2D) = "white" {} // 渐变纹理，用于控制漫反射效果
        _Specular ("Specular", Color) = (1, 1, 1, 1) // 高光颜色
        _Gloss ("Gloss", Range(8.0, 256)) = 20 // 高光的光滑度值，控制高光的聚焦程度
    }
    SubShader {
        Pass { 
            Tags { "LightMode"="ForwardBase" } // 定义光照模式为 Forward 渲染路径

            CGPROGRAM

            #pragma vertex vert // 指定顶点着色器
            #pragma fragment frag // 指定片段着色器

            #include "Lighting.cginc" // 引入 Unity 的光照计算库

            // 定义属性对应的变量
            fixed4 _Color; // 颜色叠加
            sampler2D _RampTex; // 渐变纹理
            float4 _RampTex_ST; // 渐变纹理的 Tiling 和 Offset 设置
            fixed4 _Specular; // 高光颜色
            float _Gloss; // 高光的光滑度

            // 顶点输入结构体
            struct a2v {
                float4 vertex : POSITION; // 顶点位置
                float3 normal : NORMAL; // 顶点法线
                float4 texcoord : TEXCOORD0; // UV 坐标
            };

            // 片段着色器输入结构体
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间的顶点位置
                float3 worldNormal : TEXCOORD0; // 世界空间的法线
                float3 worldPos : TEXCOORD1; // 世界空间的顶点位置
                float2 uv : TEXCOORD2; // 纹理 UV 坐标
            };

            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;
                // 将顶点从对象空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 计算世界空间的法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 计算顶点的世界空间位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 应用 Tiling 和 Offset 到 UV 坐标
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            // 片段着色器
            fixed4 frag(v2f i) : SV_Target {
                // 归一化法线向量
                fixed3 worldNormal = normalize(i.worldNormal);

                // 计算世界空间的光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 环境光分量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 使用渐变纹理对漫反射颜色进行采样
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5; // Half-Lambert 计算
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                // 漫反射分量
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                // 计算视线方向和半角向量
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光分量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 返回片段颜色值，包括环境光、漫反射和高光分量
                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    } 
    FallBack "Specular" // 设置备用着色器，当显卡不支持本着色器时使用 Specular 着色器
}
