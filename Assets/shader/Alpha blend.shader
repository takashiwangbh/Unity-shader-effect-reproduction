Shader "Unity Shaders Book/Chapter 8/Alpha Blend" {
    Properties {
        // 定义材质的颜色属性，用于为材质提供颜色调节。
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 定义主纹理，用于为材质提供贴图。
        _MainTex ("Main Tex", 2D) = "white" {}
        // 定义透明度缩放因子，影响最终输出的透明度。
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader {
        // 设置渲染队列为透明物体，并指定其为透明渲染类型。
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        
        Pass {
            // 设置渲染通道的光照模式为 ForwardBase，适合前向渲染主光源。
            Tags { "LightMode"="ForwardBase" }

            // 禁用深度写入，这样透明对象不会遮挡后面的物体。
            ZWrite Off
            // 设置 Alpha 混合模式，为普通的半透明效果 (SrcAlpha, OneMinusSrcAlpha)。
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            // 引入 Unity 的内置光照函数库。
            #include "Lighting.cginc"
            
            // 定义从 Properties 中获取的变量。
            fixed4 _Color; // 材质颜色。
            sampler2D _MainTex; // 主纹理贴图。
            float4 _MainTex_ST; // 主纹理的 Tiling 和 Offset。
            fixed _AlphaScale; // 透明度缩放因子。

            // 定义从顶点着色器输入的数据结构。
            struct a2v {
                float4 vertex : POSITION; // 顶点位置。
                float3 normal : NORMAL;   // 顶点法线。
                float4 texcoord : TEXCOORD0; // UV 坐标。
            };
            
            // 定义从顶点着色器到片段着色器传递的数据结构。
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间中的顶点位置。
                float3 worldNormal : TEXCOORD0; // 世界空间中的法线。
                float3 worldPos : TEXCOORD1; // 世界空间中的顶点位置。
                float2 uv : TEXCOORD2; // UV 坐标。
            };
            
            // 顶点着色器：将顶点数据转换为片段着色器所需的数据。
            v2f vert(a2v v) {
                v2f o;
                // 将顶点位置从对象空间转换到裁剪空间。
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将法线从对象空间转换到世界空间。
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 计算顶点的世界空间位置。
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 转换 UV 坐标，应用纹理的 Tiling 和 Offset。
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            
            // 片段着色器：计算每个像素的最终颜色。
            fixed4 frag(v2f i) : SV_Target {
                // 归一化法线和光线方向。
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 从主纹理采样颜色。
                fixed4 texColor = tex2D(_MainTex, i.uv);
                
                // 计算基础颜色 (Albedo)，为纹理颜色与材质颜色的乘积。
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                // 计算环境光颜色。
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // 计算漫反射光颜色。
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                // 返回最终颜色，将透明度乘以透明度缩放因子。
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            
            ENDCG
        }
    } 
    // 设置 Fallback，当 GPU 不支持当前着色器时使用透明材质的顶点光照着色器。
    FallBack "Transparent/VertexLit"
}
