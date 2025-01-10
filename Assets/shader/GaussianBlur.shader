/*
这个 Shader 实现了基于双 Pass 的高斯模糊效果。
通过分别在垂直方向和水平方向上模糊图像，达到了高效的模糊处理效果。
使用权重系数优化高斯模糊核的计算。
*/

Shader "Unity Shaders Book/Chapter 12/Gaussian Blur" {
    Properties {
        // 主纹理 (RGB)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 模糊范围参数
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        // 主纹理和相关参数
        sampler2D _MainTex;  
        half4 _MainTex_TexelSize; // 纹理像素大小
        float _BlurSize;          // 模糊范围
          
        // 顶点着色器输出结构
        struct v2f {
            float4 pos : SV_POSITION;  // 顶点位置
            half2 uv[5] : TEXCOORD0;   // 纹理坐标，包含 5 个采样点
        };
          
        // 垂直模糊顶点着色器
        v2f vertBlurVertical(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            half2 uv = v.texcoord;
            
            // 根据模糊范围 `_BlurSize` 计算垂直方向的采样点
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
                     
            return o;
        }
        
        // 水平模糊顶点着色器
        v2f vertBlurHorizontal(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            half2 uv = v.texcoord;
            
            // 根据模糊范围 `_BlurSize` 计算水平方向的采样点
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
                     
            return o;
        }
        
        // 片段着色器：根据高斯权重对采样点进行模糊处理
        fixed4 fragBlur(v2f i) : SV_Target {
            // 高斯权重系数，确保模糊效果自然
            float weight[3] = {0.4026, 0.2442, 0.0545};
            
            // 使用权重对中心点颜色进行处理
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            
            // 遍历采样点，分别对两侧的像素颜色应用权重
            for (int it = 1; it < 3; it++) {
                sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
            }
            
            // 返回模糊后的颜色
            return fixed4(sum, 1.0);
        }
            
        ENDCG
        
        // 设置渲染状态
        ZTest Always Cull Off ZWrite Off
        
        // 垂直模糊 Pass
        Pass {
            NAME "GAUSSIAN_BLUR_VERTICAL"
            
            CGPROGRAM
              
            #pragma vertex vertBlurVertical  
            #pragma fragment fragBlur
              
            ENDCG  
        }
        
        // 水平模糊 Pass
        Pass {  
            NAME "GAUSSIAN_BLUR_HORIZONTAL"
            
            CGPROGRAM  
            
            #pragma vertex vertBlurHorizontal  
            #pragma fragment fragBlur
            
            ENDCG
        }
    } 
    // 回退到 Diffuse Shader（如果当前 Shader 不被支持）
    FallBack "Diffuse"
}
