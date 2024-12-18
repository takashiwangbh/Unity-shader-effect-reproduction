Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
    Properties {
        // 定义用于着色器的属性
        _MainTex ("主纹理", 2D) = "white" {} // 主纹理，用于显示表面颜色
        _BumpMap ("法线贴图", 2D) = "bump" {} // 法线贴图，用于模拟表面细节
        _Cubemap ("环境立方体贴图", Cube) = "_Skybox" {} // 立方体贴图，用于环境反射
        _Distortion ("扭曲强度", Range(0, 100)) = 10 // 控制扭曲效果的强度
        _RefractAmount ("折射比例", Range(0.0, 1.0)) = 1.0 // 控制折射与反射的比例
    }
    SubShader {
        // 透明队列，确保其他对象先于当前对象渲染
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }
        
        // 此 Pass 抓取屏幕后方的内容并保存为纹理
        // 抓取的结果将在下一个 Pass 中以 _RefractionTex 访问
        GrabPass { "_RefractionTex" }
        
        Pass {        
            CGPROGRAM
            
            #pragma vertex vert // 定义顶点着色器
            #pragma fragment frag // 定义片段着色器
            
            #include "UnityCG.cginc" // 引入 Unity 的常用函数库
            
            // 声明纹理和属性
            sampler2D _MainTex; // 主纹理
            float4 _MainTex_ST; // 主纹理的缩放和平移
            sampler2D _BumpMap; // 法线贴图
            float4 _BumpMap_ST; // 法线贴图的缩放和平移
            samplerCUBE _Cubemap; // 环境立方体贴图
            float _Distortion; // 扭曲强度
            fixed _RefractAmount; // 折射比例
            sampler2D _RefractionTex; // 折射纹理
            float4 _RefractionTex_TexelSize; // 折射纹理的像素大小
            
            // 输入的顶点数据
            struct a2v {
                float4 vertex : POSITION; // 顶点位置
                float3 normal : NORMAL; // 顶点法线
                float4 tangent : TANGENT; // 顶点切线
                float2 texcoord : TEXCOORD0; // 顶点纹理坐标
            };
            
            // 顶点着色器的输出
            struct v2f {
                float4 pos : SV_POSITION; // 裁剪空间位置
                float4 scrPos : TEXCOORD0; // 屏幕空间位置
                float4 uv : TEXCOORD1; // 主纹理和法线贴图的坐标
                float4 TtoW0 : TEXCOORD2; // 切线空间到世界空间的第一行
                float4 TtoW1 : TEXCOORD3; // 切线空间到世界空间的第二行
                float4 TtoW2 : TEXCOORD4; // 切线空间到世界空间的第三行
            };
            
            // 顶点着色器
            v2f vert (a2v v) {
                v2f o;
                // 计算顶点位置的裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 计算屏幕空间坐标
                o.scrPos = ComputeGrabScreenPos(o.pos);
                
                // 计算主纹理和法线贴图的坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                
                // 将顶点位置从对象空间转换到世界空间
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
                // 计算世界空间的法线、切线和副切线
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
                
                // 构建切线空间到世界空间的变换矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
                
                return o;
            }
            
            // 片段着色器
            fixed4 frag (v2f i) : SV_Target {        
                // 从切线空间到世界空间获取法线
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                
                // 获取法线贴图的法线值（切线空间）
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));    
                
                // 在切线空间计算偏移
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
                
                // 将法线从切线空间转换到世界空间
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                // 计算反射方向
                fixed3 reflDir = reflect(-worldViewDir, bump);
                fixed4 texColor = tex2D(_MainTex, i.uv.xy);
                fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
                
                // 根据折射比例混合反射和折射颜色
                fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
                
                return fixed4(finalColor, 1); // 返回最终颜色
            }
            
            ENDCG
        }
    }
    
    // 回退到简单的 Diffuse 着色器
    FallBack "Diffuse"
}
