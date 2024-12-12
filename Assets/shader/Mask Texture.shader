Shader "Unity Shaders Book/Chapter 7/Mask Texture" {
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1) // 调整主纹理颜色的色彩叠加值
        _MainTex ("Main Tex", 2D) = "white" {} // 主要的贴图，用于定义表面颜色
        _BumpMap ("Normal Map", 2D) = "bump" {} // 法线贴图，用于模拟表面细节
        _BumpScale("Bump Scale", Float) = 1.0 // 法线强度的缩放因子
        _SpecularMask ("Specular Mask", 2D) = "white" {} // 高光遮罩贴图，用于控制表面高光的分布
        _SpecularScale ("Specular Scale", Float) = 1.0 // 高光遮罩强度的缩放因子
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
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // 主纹理的 Tiling 和 Offset 设置
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            // 输入顶点结构体
            struct a2v {
                float4 vertex : POSITION; // 顶点位置
                float3 normal : NORMAL; // 顶点法线
                float4 tangent : TANGENT; // 顶点切线，用于计算切线空间
                float4 texcoord : TEXCOORD0; // UV 坐标
            };

            // 传递给片段着色器的结构体
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间的顶点位置
                float2 uv : TEXCOORD0; // 纹理坐标
                float3 lightDir: TEXCOORD1; // 光照方向（切线空间）
                float3 viewDir : TEXCOORD2; // 视线方向（切线空间）
            };

            v2f vert(a2v v) {
                v2f o;
                // 将顶点从对象空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 计算主纹理的 UV 坐标（应用 Tiling 和 Offset）
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // 使用 Unity 提供的宏计算切线空间旋转矩阵
                TANGENT_SPACE_ROTATION;
                // 将光照方向和视线方向从对象空间转换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                // 将光照方向和视线方向归一化
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 从法线贴图中获取切线空间的法线值
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                // 使用缩放因子调整法线值的 x 和 y 分量
                tangentNormal.xy *= _BumpScale;
                // 重新计算 z 分量，确保法线向量长度为 1
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 读取主纹理颜色，并应用颜色叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 计算环境光反射分量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射分量
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 计算高光分量
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir); // 半角向量
                // 从高光遮罩贴图中获取遮罩值，并乘以缩放因子
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
                // 使用遮罩值计算高光分量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;

                // 返回最终的颜色值，包括环境光、漫反射和高光
                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    } 
    FallBack "Specular" // 设置备用着色器
}
