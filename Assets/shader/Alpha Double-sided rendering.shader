Shader "Unity Shaders Book/Chapter 8/Alpha Test With Both Side" {
    Properties {
        // 定义材质的颜色属性，供用户在 Unity Inspector 中调整。
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 定义主纹理，供用户为材质指定纹理图像。
        _MainTex ("Main Tex", 2D) = "white" {}
        // 定义 Alpha Cutoff 值，用于控制透明度裁剪的阈值。
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader {
        // 设置渲染队列为 "AlphaTest"，适合透明度裁剪。
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        
        Pass {
            // 设置渲染通道的光照模式为 ForwardBase，用于支持前向渲染的主光源光照。
            Tags { "LightMode"="ForwardBase" }
            
            // 禁用背面剔除，允许渲染物体的正反两面。
            Cull Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            // 引入 Unity 的内置光照函数库。
            #include "Lighting.cginc"
            
            // 定义从 Properties 中获取的变量。
            fixed4 _Color; // 材质的颜色。
            sampler2D _MainTex; // 主纹理。
            float4 _MainTex_ST; // 主纹理的 Tiling 和 Offset。
            fixed _Cutoff; // Alpha 裁剪的阈值。

            // 定义从顶点着色器输入的数据结构。
            struct a2v {
                float4 vertex : POSITION; // 顶点位置。
                float3 normal : NORMAL;   // 顶点法线。
                float4 texcoord : TEXCOORD0; // 顶点的 UV 坐标。
            };
            
            // 定义从顶点着色器到片段着色器传递的数据结构。
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间中的顶点位置。
                float3 worldNormal : TEXCOORD0; // 世界空间中的法线。
                float3 worldPos : TEXCOORD1; // 世界空间中的顶点位置。
                float2 uv : TEXCOORD2; // 纹理的 UV 坐标。
            };
            
            // 顶点着色器，将顶点数据转换为片段着色器所需的数据。
            v2f vert(a2v v) {
                v2f o;
                // 将顶点位置从对象空间转换为裁剪空间。
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将法线从对象空间转换为世界空间。
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // 计算顶点的世界空间位置。
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // 应用纹理的 Tiling 和 Offset。
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }
            
            // 片段着色器，计算每个像素的颜色。
            fixed4 frag(v2f i) : SV_Target {
                // 归一化法线和光线方向。
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 采样主纹理，获取纹理颜色。
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // Alpha 裁剪，根据透明度与阈值的比较决定是否丢弃像素。
                clip (texColor.a - _Cutoff);
                
                // 计算 Albedo（基础颜色）为纹理颜色与材质颜色的乘积。
                fixed3 albedo = texColor.rgb * _Color.rgb;
                
                // 计算环境光，乘以 Albedo。
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // 计算漫反射光，基于法线和光线方向的点积。
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                // 返回最终颜色，Alpha 始终为 1.0（不透明）。
                return fixed4(ambient + diffuse, 1.0);
            }
            
            ENDCG
        }
    } 
    // 设置 Fallback，指定透明度裁剪材质的替代着色器。
    FallBack "Transparent/Cutout/VertexLit"
}
