/*
这个 Shader 实现了基于光照强度的线条明暗渲染（Hatching），使用多个纹理模拟手绘风格的渐变明暗效果。

主要功能：
1. **手绘风格的明暗渐变**：
   - 根据光照强度划分区域，使用不同的线条纹理来模拟手绘效果。

2. **边缘描边**：
   - 引用了 Toon Shading 中的 OUTLINE Pass，生成模型的边缘描边。

3. **动态控制**：
   - 支持调整 Tile Factor 以控制纹理重复的密度。
   - 可自定义线条纹理、颜色和描边宽度。

4. **参数化设计**：
   - 通过多级权重实现线条纹理的渐变叠加，提供细腻的过渡效果。
  
*/

Shader "Unity Shaders Book/Chapter 14/Hatching" {
    Properties {
        // 主颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理重复因子
        _TileFactor ("Tile Factor", Float) = 1
        // 描边宽度
        _Outline ("Outline", Range(0, 1)) = 0.1
        // 线条纹理，从明亮到黑暗逐步变换
        _Hatch0 ("Hatch 0", 2D) = "white" {}
        _Hatch1 ("Hatch 1", 2D) = "white" {}
        _Hatch2 ("Hatch 2", 2D) = "white" {}
        _Hatch3 ("Hatch 3", 2D) = "white" {}
        _Hatch4 ("Hatch 4", 2D) = "white" {}
        _Hatch5 ("Hatch 5", 2D) = "white" {}
    }
    
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        
        // 引用 Toon Shading 的 OUTLINE Pass
        UsePass "Unity Shaders Book/Chapter 14/Toon Shading/OUTLINE"
        
        Pass {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag 
            
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"
            
            fixed4 _Color;
            float _TileFactor;
            sampler2D _Hatch0, _Hatch1, _Hatch2, _Hatch3, _Hatch4, _Hatch5;
            
            struct a2v {
                float4 vertex : POSITION;
                float4 tangent : TANGENT; 
                float3 normal : NORMAL; 
                float2 texcoord : TEXCOORD0; 
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed3 hatchWeights0 : TEXCOORD1;
                fixed3 hatchWeights1 : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                SHADOW_COORDS(4)
            };
            
            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _TileFactor;
                
                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = max(0, dot(worldLightDir, worldNormal)); // 光照强度
                
                o.hatchWeights0 = fixed3(0, 0, 0);
                o.hatchWeights1 = fixed3(0, 0, 0);
                
                // 根据光照强度计算纹理混合权重
                float hatchFactor = diff * 7.0;
                if (hatchFactor > 6.0) {
                    // 纯白区域
                } else if (hatchFactor > 5.0) {
                    o.hatchWeights0.x = hatchFactor - 5.0;
                } else if (hatchFactor > 4.0) {
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                } else if (hatchFactor > 3.0) {
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
                } else if (hatchFactor > 2.0) {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
                } else if (hatchFactor > 1.0) {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
                } else {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
                }
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o);
                
                return o; 
            }
            
            // 片段着色器
            fixed4 frag(v2f i) : SV_Target {            
                // 线条纹理混合
                fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;
                fixed4 whiteColor = fixed4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - 
                            i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
                
                fixed4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); // 光照衰减
                
                return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
