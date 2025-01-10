/*
这个 Shader 实现了基于亮度阈值和模糊效果的 Bloom（泛光）效果。
通过提取图像的高亮部分，并对其进行模糊处理后叠加到原始图像上，
实现画面中光晕效果的模拟，增强视觉表现力。
*/

Shader "Unity Shaders Book/Chapter 12/Bloom" {
    Properties {
        // 主纹理 (RGB)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 泛光模糊纹理
        _Bloom ("Bloom (RGB)", 2D) = "black" {}
        // 亮度阈值，高于此值的像素参与泛光效果
        _LuminanceThreshold ("Luminance Threshold", Float) = 0.5
        // 模糊范围
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        // 主纹理、模糊纹理及相关参数
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;
        
        // 顶点着色器输出结构（提取高亮部分）
        struct v2f {
            float4 pos : SV_POSITION;  // 顶点位置
            half2 uv : TEXCOORD0;      // 纹理坐标
        };    
        
        // 顶点着色器：直接传递纹理坐标
        v2f vertExtractBright(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }
        
        // 辅助函数：计算像素亮度
        fixed luminance(fixed4 color) {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
        }
        
        // 片段着色器：提取高亮部分
        fixed4 fragExtractBright(v2f i) : SV_Target {
            fixed4 c = tex2D(_MainTex, i.uv);
            // 提取高于亮度阈值的像素
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
            return c * val;
        }
        
        // 顶点着色器输出结构（用于高光叠加）
        struct v2fBloom {
            float4 pos : SV_POSITION;  // 顶点位置
            half4 uv : TEXCOORD0;      // 主纹理和模糊纹理的 UV 坐标
        };
        
        // 顶点着色器：处理主纹理和模糊纹理的 UV 坐标
        v2fBloom vertBloom(appdata_img v) {
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;        
            o.uv.zw = v.texcoord;
            
            #if UNITY_UV_STARTS_AT_TOP            
            if (_MainTex_TexelSize.y < 0.0)
                o.uv.w = 1.0 - o.uv.w;
            #endif
                        
            return o; 
        }
        
        // 片段着色器：叠加模糊高光和原始图像
        fixed4 fragBloom(v2fBloom i) : SV_Target {
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        } 
        
        ENDCG
        
        // 设置渲染状态
        ZTest Always Cull Off ZWrite Off
        
        // Pass 1：提取高亮部分
        Pass {  
            CGPROGRAM  
            #pragma vertex vertExtractBright  
            #pragma fragment fragExtractBright  
            ENDCG  
        }
        
        // 调用高斯模糊的垂直和水平 Pass
        UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"
        
        // Pass 2：叠加模糊高光和原始图像
        Pass {  
            CGPROGRAM  
            #pragma vertex vertBloom  
            #pragma fragment fragBloom  
            ENDCG  
        }
    }
    // 不支持时无回退 Shader
    FallBack Off
}
