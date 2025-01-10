/*
这个 Shader 实现了基于 Sobel 算法的屏幕后处理边缘检测效果。
通过分析每个像素的梯度，提取图像中的边缘，并允许用户自定义边缘颜色和背景颜色。
此外，用户可以通过调节参数选择是否只显示边缘或保留原始图像。
*/

Shader "Unity Shaders Book/Chapter 12/Edge Detection" {
    Properties {
        // 主纹理 (RGB)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 边缘显示强度 (0 表示完全保留原图，1 表示只显示边缘)
        _EdgeOnly ("Edge Only", Float) = 1.0
        // 边缘颜色
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        // 背景颜色
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader {
        Pass {  
            // 禁用深度测试和剔除，设置为始终渲染
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            
            #pragma vertex vert  
            #pragma fragment fragSobel
            
            // 主纹理
            sampler2D _MainTex;  
            // 用于计算像素大小
            uniform half4 _MainTex_TexelSize;
            // 边缘显示强度
            fixed _EdgeOnly;
            // 边缘颜色
            fixed4 _EdgeColor;
            // 背景颜色
            fixed4 _BackgroundColor;
            
            // 顶点着色器输出结构
            struct v2f {
                float4 pos : SV_POSITION;  // 顶点位置
                half2 uv[9] : TEXCOORD0;   // 9 个纹理采样点
            };
              
            // 顶点着色器：计算每个像素的邻域 UV 坐标，用于边缘检测
            v2f vert(appdata_img v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                half2 uv = v.texcoord;
                
                // 计算周围 8 个像素的 UV 偏移量
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                         
                return o;
            }
            
            // 辅助函数：计算像素的亮度
            fixed luminance(fixed4 color) {
                return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
            }
            
            // Sobel 算法：计算图像梯度并返回边缘强度
            half Sobel(v2f i) {
                // Sobel 算法的 Gx 和 Gy 核
                const half Gx[9] = {-1,  0,  1,
                                     -2,  0,  2,
                                     -1,  0,  1};
                const half Gy[9] = {-1, -2, -1,
                                      0,  0,  0,
                                      1,  2,  1};        
                
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                // 遍历 3x3 的像素块，计算梯度
                for (int it = 0; it < 9; it++) {
                    texColor = luminance(tex2D(_MainTex, i.uv[it]));
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }
                
                // 计算边缘强度
                half edge = 1 - abs(edgeX) - abs(edgeY);
                
                return edge;
            }
            
            // 片段着色器：根据 Sobel 边缘强度计算最终颜色
            fixed4 fragSobel(v2f i) : SV_Target {
                // 计算边缘强度
                half edge = Sobel(i);
                
                // 使用边缘颜色混合原图和背景
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                // 根据 _EdgeOnly 参数决定最终效果
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            
            ENDCG
        } 
    }
    FallBack Off
}
