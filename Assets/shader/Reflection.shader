Shader "Unity Shaders Book/Chapter 10/Reflection" {
    // 定义属性，供用户在 Unity Inspector 面板中调整参数
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)                   // 基础颜色
        _ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)     // 反射颜色
        _ReflectAmount ("Reflect Amount", Range(0, 1)) = 1           // 反射强度
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}         // 用于反射的立方体贴图（Cubemap）
    }
    SubShader {
        // 定义渲染队列和类型
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass { 
            Tags { "LightMode"="ForwardBase" } // 基本光照模式，Forward 渲染管线中基础光照通道
            
            CGPROGRAM
            
            #pragma multi_compile_fwdbase        // 支持前向渲染的基础光照
            #pragma vertex vert                  // 顶点着色器
            #pragma fragment frag                // 片元着色器
            
            #include "Lighting.cginc"            // 包含光照计算的库文件
            #include "AutoLight.cginc"           // 包含自动光照相关的定义
            
            // 声明属性变量
            fixed4 _Color;                       // 基础颜色
            fixed4 _ReflectColor;                // 反射颜色
            fixed _ReflectAmount;                // 反射强度
            samplerCUBE _Cubemap;                // 反射用的立方体贴图（Cubemap）

            // 定义顶点着色器输入结构体
            struct a2v {
                float4 vertex : POSITION;        // 输入的顶点位置
                float3 normal : NORMAL;          // 输入的顶点法线
            };

            // 定义顶点着色器输出结构体
            struct v2f {
                float4 pos : SV_POSITION;        // 裁剪空间坐标
                float3 worldPos : TEXCOORD0;     // 世界坐标
                fixed3 worldNormal : TEXCOORD1;  // 世界法线
                fixed3 worldViewDir : TEXCOORD2; // 世界空间的视角方向
                fixed3 worldRefl : TEXCOORD3;    // 世界空间的反射方向
                SHADOW_COORDS(4)                 // 阴影坐标（宏定义，自动处理阴影）
            };

            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;
                
                // 将物体坐标转换为裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将法线从物体空间转换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // 计算顶点的世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // 计算从顶点到相机的方向向量（世界空间）
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                // 计算反射向量：基于观察方向和法线，得到世界空间反射方向
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
                
                // 传输阴影坐标（用于阴影计算）
                TRANSFER_SHADOW(o);
                
                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target {
                // 归一化世界法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 归一化世界光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 归一化世界观察方向
                fixed3 worldViewDir = normalize(i.worldViewDir);
                
                // 获取环境光颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 计算漫反射颜色：光照颜色 * 基础颜色 * 法线与光照方向的点积
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 使用反射向量采样立方体贴图，实现环境反射效果
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;
                
                // 计算光照衰减（阴影计算）
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // 使用反射颜色与漫反射颜色进行混合：根据反射强度 _ReflectAmount 混合漫反射与反射效果
                fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
                
                // 返回最终颜色，alpha 为 1（完全不透明）
                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    }
    // 备用 Shader，当目标平台不支持当前 Shader 时使用的回退选项
    FallBack "Reflective/VertexLit"
}
