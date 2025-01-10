/*
这个 Shader 实现了基于深度纹理的运动模糊效果。
通过记录当前帧和上一帧的视图投影矩阵，计算像素的屏幕速度，并在图像渲染过程中利用速度对纹理进行采样，实现运动模糊的效果。
*/

Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
    Properties {
        // 主纹理 (RGB)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 模糊强度
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        // 主纹理
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        // 摄像机的深度纹理
        sampler2D _CameraDepthTexture;
        // 当前帧的视图投影逆矩阵
        float4x4 _CurrentViewProjectionInverseMatrix;
        // 上一帧的视图投影矩阵
        float4x4 _PreviousViewProjectionMatrix;
        // 模糊强度
        half _BlurSize;
        
        // 顶点着色器输出结构
        struct v2f {
            float4 pos : SV_POSITION;   // 顶点位置
            half2 uv : TEXCOORD0;       // 纹理坐标
            half2 uv_depth : TEXCOORD1; // 深度纹理坐标
        };
        
        // 顶点着色器
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); // 计算裁剪空间位置
            
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord; // 用于深度纹理采样
            
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y; // 修正 UV 坐标
            #endif
                     
            return o;
        }
        
        // 片段着色器
        fixed4 frag(v2f i) : SV_Target {
            // 从深度纹理获取深度值
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            // 计算视口坐标范围 [-1, 1]
            float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
            // 使用当前视图投影逆矩阵计算世界坐标
            float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
            float4 worldPos = D / D.w; // 转换为非齐次坐标
            
            // 当前视口位置
            float4 currentPos = H;
            // 使用上一帧的视图投影矩阵将世界坐标转换为上一帧的视口位置
            float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
            previousPos /= previousPos.w; // 转换为非齐次坐标
            
            // 计算像素速度
            float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;
            
            // 运动模糊采样
            float2 uv = i.uv;
            float4 c = tex2D(_MainTex, uv); // 初始颜色
            uv += velocity * _BlurSize;
            for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
                float4 currentColor = tex2D(_MainTex, uv); // 模糊采样
                c += currentColor;
            }
            c /= 3; // 平均采样结果
            
            return fixed4(c.rgb, 1.0); // 返回模糊后的颜色
        }
        
        ENDCG
        
        // 渲染 Pass
        Pass {      
            ZTest Always Cull Off ZWrite Off
                
            CGPROGRAM  
            #pragma vertex vert  
            #pragma fragment frag  
            ENDCG  
        }
    } 
    FallBack Off
}
