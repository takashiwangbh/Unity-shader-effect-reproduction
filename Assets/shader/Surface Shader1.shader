// 这个Shader是一个Surface Shader，用于渲染具有颜色、纹理和法线贴图效果的物体。
// 它支持一个颜色贴图（Albedo Map）、一个法线贴图（Normal Map），并允许通过颜色调整物体的外观。
// 使用了Lambert光照模型，支持Shader Model 3.0，并提供对老旧硬件的Fallback功能。

Shader "Surface Shader1" {
    Properties {
        // 物体的主颜色，可用于调整纹理的颜色。
        _Color ("主颜色", Color) = (1,1,1,1)
        // 提供物体颜色信息的基础纹理（Albedo贴图）。
        _MainTex ("基础纹理 (RGB)", 2D) = "white" {}
        // 提供表面细节的法线贴图，用于光照计算。
        _BumpMap ("法线贴图", 2D) = "bump" {}
    }
    SubShader {
        // 该标签定义渲染类型为不透明（Opaque）。
        Tags { "RenderType"="Opaque" }
        // 指定这个Shader的细节等级（LOD）。
        LOD 300
        
        CGPROGRAM
        // 定义这是一个Surface Shader，使用Lambert光照模型。
        #pragma surface surf Lambert
        // 确保该Shader支持Shader Model 3.0或更高版本。
        #pragma target 3.0

        // 声明Shader中使用的纹理。
        sampler2D _MainTex;
        sampler2D _BumpMap;
        // 声明用于调整颜色的属性。
        fixed4 _Color;

        // 定义输入数据的结构体，用于传递到表面函数。
        struct Input {
            // 用于采样基础纹理的UV坐标。
            float2 uv_MainTex;
            // 用于采样法线贴图的UV坐标。
            float2 uv_BumpMap;
        };

        // 主表面函数，负责定义材质的外观。
        void surf (Input IN, inout SurfaceOutput o) {
            // 使用提供的UV坐标采样基础纹理。
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            // 设置漫反射颜色，将纹理的RGB值与颜色属性相乘。
            o.Albedo = tex.rgb * _Color.rgb;
            // 设置透明度，将纹理的Alpha值与颜色属性的Alpha相乘。
            o.Alpha = tex.a * _Color.a;
            // 应用法线贴图，修改表面的光照法线以实现细节光照效果。
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }
        
        ENDCG
    } 
    
    // 对于不支持该Shader的老旧硬件，使用Fallback的Legacy Diffuse Shader。
    FallBack "Legacy Shaders/Diffuse"
}
