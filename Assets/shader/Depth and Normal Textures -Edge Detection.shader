/*
这个 Shader 实现了基于法线和深度的边缘检测效果，结合 Robert Cross 算法对纹理的深度和法线进行比较，从而提取边缘信息。
*/

Shader "Unity Shaders Book/Chapter 13/Edge Detection Normals And Depth" {
    Properties {
        // 主纹理
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 边缘显示强度
        _EdgeOnly ("Edge Only", Float) = 1.0
        // 边缘颜色
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        // 背景颜色
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
        // 采样距离
        _SampleDistance ("Sample Distance", Float) = 1.0
        // 灵敏度参数
        _Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        // 变量定义
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        fixed _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        half4 _Sensitivity;
        sampler2D _CameraDepthNormalsTexture;

        // 顶点着色器输出结构
        struct v2f {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };
        
        // 顶点着色器
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); // 计算裁剪空间位置
            
            half2 uv = v.texcoord;
            o.uv[0] = uv;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                uv.y = 1 - uv.y; // 修正 UV 坐标方向
            #endif
            
            // 计算采样点的 UV 偏移
            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance;
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance;
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance;
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance;

            return o;
        }
        
        // 比较深度和法线差异，判断是否为边缘
        half CheckSame(half4 center, half4 sample) {
            half2 centerNormal = center.xy;             // 中心像素的法线
            float centerDepth = DecodeFloatRG(center.zw); // 中心像素的深度
            half2 sampleNormal = sample.xy;             // 相邻像素的法线
            float sampleDepth = DecodeFloatRG(sample.zw); // 相邻像素的深度
            
            // 计算法线差异
            half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
            int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
            
            // 计算深度差异
            float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
            int isSameDepth = diffDepth < 0.1 * centerDepth;

            // 返回 1 表示相似，0 表示边缘
            return isSameNormal * isSameDepth ? 1.0 : 0.0;
        }
        
        // 片段着色器
        fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target {
            // 获取相邻像素的深度和法线数据
            half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
            half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
            half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
            half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
            
            // 判断边缘
            half edge = 1.0;
            edge *= CheckSame(sample1, sample2);
            edge *= CheckSame(sample3, sample4);
            
            // 根据边缘显示强度插值颜色
            fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
            fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
            
            return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly); // 返回最终颜色
        }
        
        ENDCG
        
        // 渲染 Pass
        Pass { 
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM      
            #pragma vertex vert  
            #pragma fragment fragRobertsCrossDepthAndNormal
            ENDCG  
        }
    } 
    FallBack Off
}
