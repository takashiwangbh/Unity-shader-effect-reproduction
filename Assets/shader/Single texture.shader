Shader "Unity Shaders Book/Chapter 7/Single Texture" {
    Properties {
        // 用于控制整个材质颜色的颜色属性
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 主纹理，用于叠加纹理颜色
        _MainTex ("Main Tex", 2D) = "white" {}
        // 镜面反射的颜色属性
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 控制镜面反射光泽度的范围属性
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader {        
        Pass { 
            // 指定渲染通道为 ForwardBase
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            
            #pragma vertex vert // 指定顶点函数
            #pragma fragment frag // 指定片段函数

            #include "Lighting.cginc" // 引入 Unity 的光照函数库
            
            // 定义用于材质属性的变量
            fixed4 _Color; 
            sampler2D _MainTex; // 定义采样器，用于纹理采样
            float4 _MainTex_ST; // 用于纹理缩放和偏移的变换矩阵
            fixed4 _Specular;
            float _Gloss;

            // 顶点输入结构，包含顶点位置、法线和纹理坐标
            struct a2v {
                float4 vertex : POSITION; // 顶点位置
                float3 normal : NORMAL; // 顶点法线
                float4 texcoord : TEXCOORD0; // 顶点纹理坐标
            };
            
            // 顶点到片段的输出结构，包含世界空间信息和纹理坐标
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间位置
                float3 worldNormal : TEXCOORD0; // 世界空间法线
                float3 worldPos : TEXCOORD1; // 世界空间顶点位置
                float2 uv : TEXCOORD2; // 纹理坐标
            };
            
            // 顶点函数
            v2f vert(a2v v) {
                v2f o;
                // 将顶点从对象空间变换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将法线从对象空间变换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                // 将顶点从对象空间变换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // 计算纹理坐标，应用纹理缩放和偏移
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 或者直接使用内置函数
                // o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }
            
            // 片段函数
            fixed4 frag(v2f i) : SV_Target {
                // 规范化法线向量
                fixed3 worldNormal = normalize(i.worldNormal);
                // 规范化光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 使用纹理采样获取漫反射颜色
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                // 计算环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // 计算漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                // 计算观察方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 计算半向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 计算镜面反射
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                // 返回最终颜色，包含环境光、漫反射和镜面反射
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    } 
    // 如果不支持此 Shader，回退到默认镜面 Shader
    FallBack "Specular"
}
