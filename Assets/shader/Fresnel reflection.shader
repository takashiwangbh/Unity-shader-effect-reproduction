Shader "Unity Shaders Book/Chapter 10/Fresnel" {
    // 定义可调节的属性
    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)          // 物体基础颜色
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.5  // Fresnel 效应的强度系数
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {} // 反射所用的环境贴图（立方体贴图）
    }
    
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"} // 设置渲染类型和渲染队列
        
        Pass { 
            Tags { "LightMode"="ForwardBase" } // 定义为 ForwardBase 光照模式
            
            CGPROGRAM
            
            #pragma multi_compile_fwdbase       // 支持前向渲染的多光源
            #pragma vertex vert                 // 顶点着色器入口
            #pragma fragment frag               // 片元着色器入口
            
            #include "Lighting.cginc"           // 包含基础光照计算函数
            #include "AutoLight.cginc"          // 包含自动阴影坐标计算函数
            
            // 定义外部属性
            fixed4 _Color;                     // 基础颜色
            fixed _FresnelScale;               // Fresnel 效应强度
            samplerCUBE _Cubemap;              // 立方体贴图（反射环境）
            
            // 定义顶点输入结构
            struct a2v {
                float4 vertex : POSITION;      // 模型空间的顶点位置
                float3 normal : NORMAL;        // 模型空间的法线
            };
            
            // 顶点输出结构
            struct v2f {
                float4 pos : SV_POSITION;      // 裁剪空间位置
                float3 worldPos : TEXCOORD0;   // 世界空间顶点位置
                fixed3 worldNormal : TEXCOORD1; // 世界空间法线
                fixed3 worldViewDir : TEXCOORD2; // 世界空间视角方向
                fixed3 worldRefl : TEXCOORD3;  // 世界空间反射向量
                SHADOW_COORDS(4)               // 存储阴影坐标
            };
            
            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;
                // 将顶点从对象空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将法线从对象空间转换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // 计算世界空间顶点位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // 计算世界空间的视角方向（从顶点指向相机）
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                
                // 计算反射向量（视角方向反射到法线上）
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
                
                // 传递阴影坐标（用于阴影计算）
                TRANSFER_SHADOW(o);
                
                return o;
            }
            
            // 片元着色器
            fixed4 frag(v2f i) : SV_Target {
                // 归一化世界空间的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 归一化世界空间的光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 归一化世界空间的视角方向
                fixed3 worldViewDir = normalize(i.worldViewDir);
                
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 计算阴影衰减值
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // 从立方体贴图中采样反射颜色
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;
                
                // 计算 Fresnel 系数
                // Fresnel = 基础强度 + (1 - 基础强度) * (1 - cos(视角方向与法线夹角))^5
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);
                
                // 计算漫反射光照
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 混合漫反射颜色与反射颜色，根据 Fresnel 系数调整
                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;
                
                // 返回最终颜色，alpha 设为 1.0
                return fixed4(color, 1.0);
            }
            
            ENDCG
        }
    } 
    
    FallBack "Reflective/VertexLit" // 回退到低级别的反射 VertexLit Shader
}
