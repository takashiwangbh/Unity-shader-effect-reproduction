/*
这个 Shader 实现了卡通渲染（Toon Shading）效果，结合边缘描边与简化的光照模型，为模型提供一种独特的卡通风格。

主要功能：
1. **描边效果**：
   - 利用顶点偏移的方式实现模型的边缘描边。
   - 支持自定义描边颜色和宽度。

2. **卡通光照**：
   - 使用 Ramp 纹理控制光照的渐变，实现分段的卡通风格光照。
   - 包含环境光、漫反射光、以及简单的高光处理。

3. **参数可控**：
   - 支持通过 `Inspector` 自定义颜色、光照参数、描边属性等。

*/

Shader "Unity Shaders Book/Chapter 14/Toon Shading" {
    Properties {
        // 基础颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 主要纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        // Ramp 纹理，用于卡通光照控制
        _Ramp ("Ramp Texture", 2D) = "white" {}
        // 描边宽度
        _Outline ("Outline", Range(0, 1)) = 0.1
        // 描边颜色
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        // 高光颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 高光强度
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // Pass 1: 描边效果
        Pass {
            NAME "OUTLINE"
            
            Cull Front // 剔除正面，保留背面用于描边
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            float _Outline;
            fixed4 _OutlineColor;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            }; 
            
            struct v2f {
                float4 pos : SV_POSITION;
            };
            
            // 顶点着色器，用于顶点偏移实现描边
            v2f vert (a2v v) {
                v2f o;
                
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex); 
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);  
                pos = pos + float4(normalize(normal), 0) * _Outline;
                o.pos = mul(UNITY_MATRIX_P, pos);
                
                return o;
            }
            
            // 片段着色器，渲染描边颜色
            float4 frag(v2f i) : SV_Target { 
                return float4(_OutlineColor.rgb, 1);               
            }
            
            ENDCG
        }

        // Pass 2: 卡通光照效果
        Pass {
            Tags { "LightMode"="ForwardBase" }
            
            Cull Back // 剔除背面，仅渲染正面
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;
            
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            }; 
            
            struct v2f {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };
            
            // 顶点着色器，用于卡通光照计算
            v2f vert (a2v v) {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            // 片段着色器，渲染卡通光照效果
            float4 frag(v2f i) : SV_Target { 
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
                
                // 基础纹理与颜色
                fixed4 c = tex2D(_MainTex, i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;
                
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // 漫反射光照
                fixed diff = dot(worldNormal, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;
                
                // 高光
                fixed spec = dot(worldNormal, worldHalfDir);
                fixed w = fwidth(spec) * 2.0;
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                
                // 返回最终颜色
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
