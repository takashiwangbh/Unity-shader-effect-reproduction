Shader "Unity Shaders Book/Chapter 6/Blinn-Phong" {
    Properties {
        // 定义材质属性：
        // _Diffuse 表示漫反射颜色。
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        // _Specular 表示镜面反射颜色。
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // _Gloss 表示光泽度，数值越高，高光越锐利。
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader {
        Pass { 
            // 设置光照模式为 ForwardBase，即正向渲染中使用基础光源。
            Tags { "LightMode"="ForwardBase" }
        
            CGPROGRAM
            
            // 定义顶点着色器和片元着色器的入口。
            #pragma vertex vert
            #pragma fragment frag
            
            // 包含 Unity 的光照计算函数库。
            #include "Lighting.cginc"
            
            // 定义材质属性的变量
            fixed4 _Diffuse;  // 漫反射颜色
            fixed4 _Specular; // 镜面反射颜色
            float _Gloss;     // 光泽度
            
            // 定义从顶点着色器输入的结构体
            struct a2v {
                float4 vertex : POSITION; // 顶点位置
                float3 normal : NORMAL;  // 法线方向
            };
            
            // 定义从顶点着色器传递到片元着色器的数据
            struct v2f {
                float4 pos : SV_POSITION;      // 裁剪空间中的顶点位置
                float3 worldNormal : TEXCOORD0; // 世界空间中的法线
                float3 worldPos : TEXCOORD1;   // 世界空间中的顶点位置
            };
            
            // 顶点着色器
            v2f vert(a2v v) {
                v2f o;
                // 将顶点从对象空间变换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将法线从对象空间变换到世界空间
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                
                // 将顶点从对象空间变换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                return o; // 返回给片元着色器
            }
            
            // 片元着色器
            fixed4 frag(v2f i) : SV_Target {
                // 计算环境光分量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 法线和光线方向变换到世界空间
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // 计算漫反射分量
                // dot 函数计算光线方向与法线方向的余弦值，值范围在 0~1。
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                
                // 计算镜面反射分量（Blinn-Phong 使用半向量）
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); // 视线方向
                fixed3 halfDir = normalize(worldLightDir + viewDir); // 半向量
                // dot(worldNormal, halfDir) 计算法线和半向量的夹角余弦值。
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
                
                // 最终颜色由环境光、漫反射、镜面反射相加得出。
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    } 
    // 备用 Shader，当设备不支持时使用默认的 Specular Shader。
    FallBack "Specular"
}
