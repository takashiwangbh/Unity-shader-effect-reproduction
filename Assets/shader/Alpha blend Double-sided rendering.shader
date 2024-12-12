Shader "Unity Shaders Book/Chapter 8/Alpha Blend With Both Side" {
    Properties {
        // 定义颜色调节属性
        _Color ("Color Tint", Color) = (1, 1, 1, 1) 

        // 定义主纹理属性
        _MainTex ("Main Tex", 2D) = "white" {}

        // 定义透明度缩放属性，用于控制材质的透明度
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }

    SubShader {
        // 给Shader标记为透明物体，并禁用与投影仪的交互
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        // 第一个Pass只渲染背面
        Pass {
            Tags { "LightMode"="ForwardBase" }

            // 排除正面，只渲染背面
            Cull Front

            // 关闭ZWrite（深度写入），并使用源透明度与目标透明度混合
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"  // 引入光照计算

            // 声明Shader属性
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            // 定义顶点输入结构体（从模型传入的属性）
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            // 定义顶点输出结构体（传递给片段着色器）
            struct v2f {
                float4 pos : SV_POSITION;    // 屏幕空间的位置
                float3 worldNormal : TEXCOORD0;  // 世界空间中的法线
                float3 worldPos : TEXCOORD1;     // 世界空间中的位置
                float2 uv : TEXCOORD2;           // 纹理坐标
            };

            // 顶点着色器：将顶点位置转换到屏幕空间
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  // 转换到剪辑空间

                o.worldNormal = UnityObjectToWorldNormal(v.normal);  // 计算世界空间中的法线

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  // 计算世界空间中的位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  // 转换纹理坐标

                return o;
            }

            // 片段着色器：计算颜色和光照
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);  // 归一化世界空间中的法线
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));  // 计算世界空间中的光照方向

                fixed4 texColor = tex2D(_MainTex, i.uv);  // 获取纹理颜色

                fixed3 albedo = texColor.rgb * _Color.rgb;  // 计算颜色（纹理颜色乘以颜色调节）

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;  // 计算环境光照

                // 计算漫反射光照（使用光照方向和法线的点积）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);  // 返回最终颜色，包含环境光和漫反射光
            }

            ENDCG
        }

        // 第二个Pass只渲染正面
        Pass {
            Tags { "LightMode"="ForwardBase" }

            // 排除背面，只渲染正面
            Cull Back

            // 关闭ZWrite（深度写入），并使用源透明度与目标透明度混合
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"  // 引入光照计算

            // 声明Shader属性
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            // 定义顶点输入结构体（从模型传入的属性）
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            // 定义顶点输出结构体（传递给片段着色器）
            struct v2f {
                float4 pos : SV_POSITION;    // 屏幕空间的位置
                float3 worldNormal : TEXCOORD0;  // 世界空间中的法线
                float3 worldPos : TEXCOORD1;     // 世界空间中的位置
                float2 uv : TEXCOORD2;           // 纹理坐标
            };

            // 顶点着色器：将顶点位置转换到屏幕空间
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  // 转换到剪辑空间

                o.worldNormal = UnityObjectToWorldNormal(v.normal);  // 计算世界空间中的法线

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  // 计算世界空间中的位置

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  // 转换纹理坐标

                return o;
            }

            // 片段着色器：计算颜色和光照
            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);  // 归一化世界空间中的法线
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));  // 计算世界空间中的光照方向

                fixed4 texColor = tex2D(_MainTex, i.uv);  // 获取纹理颜色

                fixed3 albedo = texColor.rgb * _Color.rgb;  // 计算颜色（纹理颜色乘以颜色调节）

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;  // 计算环境光照

                // 计算漫反射光照（使用光照方向和法线的点积）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);  // 返回最终颜色，包含环境光和漫反射光
            }

            ENDCG
        }
    }

    // 使用透明物体的标准渲染设置作为回退
    FallBack "Transparent/VertexLit"
}
