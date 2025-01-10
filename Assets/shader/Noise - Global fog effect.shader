
// 实现一个基于深度和噪声的全局雾效。
// 通过结合相机的深度纹理和噪声纹理，动态计算雾气的浓度和变化，最终生成带有随机性的自然雾效。
// 属性包括雾的密度、颜色、起始和结束距离，以及噪声的影响。

Shader "Noise - Global fog effect" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {} // 场景基础纹理
        _FogDensity ("Fog Density", Float) = 1.0 // 雾气浓度
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1) // 雾的颜色
        _FogStart ("Fog Start", Float) = 0.0 // 雾效开始的距离
        _FogEnd ("Fog End", Float) = 1.0 // 雾效结束的距离
        _NoiseTex ("Noise Texture", 2D) = "white" {} // 噪声纹理，用于动态变化
        _FogXSpeed ("Fog Horizontal Speed", Float) = 0.1 // 雾气水平流动速度
        _FogYSpeed ("Fog Vertical Speed", Float) = 0.1 // 雾气垂直流动速度
        _NoiseAmount ("Noise Amount", Float) = 1 // 噪声对雾气的影响强度
    }
    SubShader {
        CGINCLUDE
        
        #include "UnityCG.cginc"

        // 定义全局矩阵和纹理采样器
        float4x4 _FrustumCornersRay; // 用于计算屏幕空间到世界空间的光线方向

        sampler2D _MainTex; // 场景基础纹理
        half4 _MainTex_TexelSize; // 主纹理的像素大小
        sampler2D _CameraDepthTexture; // 相机的深度纹理
        half _FogDensity; // 雾气浓度
        fixed4 _FogColor; // 雾的颜色
        float _FogStart; // 雾效开始的距离
        float _FogEnd; // 雾效结束的距离
        sampler2D _NoiseTex; // 噪声纹理
        half _FogXSpeed; // 雾气水平移动速度
        half _FogYSpeed; // 雾气垂直移动速度
        half _NoiseAmount; // 噪声对雾气影响的强度

        // 定义顶点与片元之间的结构体
        struct v2f {
            float4 pos : SV_POSITION; // 顶点的屏幕坐标
            float2 uv : TEXCOORD0; // 主纹理的UV坐标
            float2 uv_depth : TEXCOORD1; // 深度纹理的UV坐标
            float4 interpolatedRay : TEXCOORD2; // 从屏幕空间到世界空间的光线
        };

        // 顶点着色器，用于计算光线方向和UV坐标
        v2f vert(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex); // 转换为屏幕空间坐标
            
            // 计算纹理的UV坐标
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;

            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y; // 修正UV坐标
            #endif
            
            // 根据顶点的位置，选择插值光线方向
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
                index = 3 - index; // 修正索引
            #endif
            
            o.interpolatedRay = _FrustumCornersRay[index]; // 获取光线方向
                 
            return o;
        }

        // 片元着色器，用于计算最终的雾效颜色
        fixed4 frag(v2f i) : SV_Target {
            // 线性深度，转换屏幕深度值为世界深度值
            float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz; // 世界空间位置
            
            // 计算噪声影响
            float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed); // 动态噪声移动速度
            float noise = (tex2D(_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount; // 获取噪声值
            
            // 雾气浓度，根据深度和噪声调整
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
            fogDensity = saturate(fogDensity * _FogDensity * (1 + noise)); // 最终浓度
            
            // 混合雾的颜色与场景颜色
            fixed4 finalColor = tex2D(_MainTex, i.uv); // 场景颜色
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity); // 混合结果
            
            return finalColor; // 返回最终颜色
        }
        
        ENDCG
        
        // 渲染通道
        Pass {              
            CGPROGRAM  
            
            #pragma vertex vert  
            #pragma fragment frag  
              
            ENDCG
        }
    } 
    FallBack Off // 无需降级到默认Shader
}
