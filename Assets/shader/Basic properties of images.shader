/*
这个 Shader 用于调整图像的亮度、饱和度和对比度。
开发者可以通过在 Unity Inspector 中设置对应的参数值，
实时改变画面效果，从而实现所需的图像调整功能。
*/

Shader "Basic properties of images" {
    Properties {
        // 定义 Shader 可调节的属性：主纹理、亮度、饱和度和对比度
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Brightness ("Brightness", Float) = 1
        _Saturation("Saturation", Float) = 1
        _Contrast("Contrast", Float) = 1
    }
    SubShader {
        Pass {  
            // 禁用深度测试和剔除，设置为始终渲染
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM  
            #pragma vertex vert  
            #pragma fragment frag  
              
            #include "UnityCG.cginc"  
              
            // 定义纹理和调节参数
            sampler2D _MainTex;  
            half _Brightness;
            half _Saturation;
            half _Contrast;
              
            // 顶点着色器输出结构
            struct v2f {
                float4 pos : SV_POSITION;  // 顶点位置
                half2 uv: TEXCOORD0;       // 纹理坐标
            };
              
            // 顶点着色器：将顶点坐标转换为剪辑空间坐标，并传递纹理坐标
            v2f vert(appdata_img v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
        
            // 片段着色器：对图像像素应用亮度、饱和度和对比度调整
            fixed4 frag(v2f i) : SV_Target {
                // 读取纹理像素颜色
                fixed4 renderTex = tex2D(_MainTex, i.uv);  
                  
                // 调整亮度
                fixed3 finalColor = renderTex.rgb * _Brightness;
                
                // 调整饱和度
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b; // 计算亮度值
                fixed3 luminanceColor = fixed3(luminance, luminance, luminance); // 构造灰度图
                finalColor = lerp(luminanceColor, finalColor, _Saturation); // 根据饱和度插值
                
                // 调整对比度
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5); // 基准值
                finalColor = lerp(avgColor, finalColor, _Contrast); // 根据对比度插值
                
                // 返回调整后的颜色，保留原始透明度
                return fixed4(finalColor, renderTex.a);  
            }  
              
            ENDCG
        }  
    }
    
    // 禁用回退到默认 Shader
    Fallback Off
}
