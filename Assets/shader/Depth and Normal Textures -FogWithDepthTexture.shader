/*
这个 Shader 实现了基于深度纹理的屏幕后处理雾效。
通过结合视锥体角点和深度纹理信息，计算出每个像素的世界坐标，
并根据用户设置的雾参数（颜色、密度、范围）生成真实感的雾效。
*/

Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
    Properties {
        // 主纹理 (RGB)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 雾的密度
        _FogDensity ("Fog Density", Float) = 1.0
        // 雾的颜色
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        // 雾的起始距离
        _FogStart ("Fog Start", Float) = 0.0
        // 雾的结束距离
        _FogEnd ("Fog End", Float) = 1.0
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        // 定义需要的变量
        float4x4 _FrustumCornersRay;   // 视锥体角点矩阵
        sampler2D _MainTex;            // 主纹理
        half4 _MainTex_TexelSize;      // 主纹理的像素大小
        sampler2D _CameraDepthTexture; // 深度纹理
        half _FogDensity;              // 雾的密度
        fixed4 _FogColor;              // 雾的颜色
        float _FogStart;               // 雾的起始距离
        float _FogEnd;                 // 雾的结束距离
        
        // 顶点着色器的输出结构
        struct v2f {
            float4 pos : SV_POSITION;       // 裁剪空间位置
            half2 uv : TEXCOORD0;           // 主纹理 UV 坐标
            half2 uv_depth : TEXCOORD1;     // 深度纹理 UV 坐标
            float4 interpolatedRay : TEXCOORD2; // 插值后的视锥射线方向
        };
        
        // 顶点着色器
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); // 计算裁剪空间位置
            
            o.uv = v.texcoord;          // 主纹理 UV 坐标
            o.uv_depth = v.texcoord;    // 深度纹理 UV 坐标
            
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y; // 修正 UV 坐标方向
            #endif
            
            // 根据纹理坐标确定视锥体的角点索引
            int index = 0;
            if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
                index = 0;
            } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
                index = 1;
            } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                index = 2;
            } else {
                index = 3;
            }

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                index = 3 - index; // 修正角点索引
            #endif
            
            o.interpolatedRay = _FrustumCornersRay[index]; // 设置插值后的视锥射线方向
                     
            return o;
        }
        
        // 片段着色器
        fixed4 frag(v2f i) : SV_Target {
            // 获取线性深度
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            // 计算世界坐标
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                        
            // 根据雾的起始和结束范围计算雾密度
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
            fogDensity = saturate(fogDensity * _FogDensity);
            
            // 获取原始颜色并混合雾的颜色
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
            
            return finalColor; // 返回最终颜色
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
