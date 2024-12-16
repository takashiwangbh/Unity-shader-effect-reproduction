Shader "Unity Shaders Book/Chapter 10/Refraction" {
	// 定义属性，用于在材质面板中调整参数
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1) // 基础颜色
		_RefractColor ("Refraction Color", Color) = (1, 1, 1, 1) // 折射颜色
		_RefractAmount ("Refraction Amount", Range(0, 1)) = 1 // 折射混合程度
		_RefractRatio ("Refraction Ratio", Range(0.1, 1)) = 0.5 // 折射率
		_Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {} // 折射所使用的 Cubemap 贴图
	}
	
	// 定义 SubShader，指定渲染标签
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		
		Pass { 
			Tags { "LightMode"="ForwardBase" } // 前向渲染模式
			
			CGPROGRAM
			
			// 编译选项
			#pragma multi_compile_fwdbase
			#pragma vertex vert // 指定顶点着色器
			#pragma fragment frag // 指定片元着色器
			
			// 引入常用的光照函数
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			// 声明属性变量
			fixed4 _Color;          // 基础颜色
			fixed4 _RefractColor;   // 折射颜色
			float _RefractAmount;   // 折射的混合程度（0 到 1）
			fixed _RefractRatio;    // 折射率（控制折射角度）
			samplerCUBE _Cubemap;   // 折射使用的立方体贴图（Cubemap）
			
			// 输入结构体 a2v（从顶点数据传入）
			struct a2v {
				float4 vertex : POSITION; // 顶点位置
				float3 normal : NORMAL;   // 法线方向
			};
			
			// 输出结构体 v2f（从顶点着色器传递到片元着色器）
			struct v2f {
				float4 pos : SV_POSITION;       // 裁剪空间中的顶点位置
				float3 worldPos : TEXCOORD0;    // 世界坐标中的顶点位置
				fixed3 worldNormal : TEXCOORD1; // 世界坐标中的法线方向
				fixed3 worldViewDir : TEXCOORD2;// 从观察者到顶点的方向（世界空间）
				fixed3 worldRefr : TEXCOORD3;   // 折射方向（世界空间）
				SHADOW_COORDS(4)               // 用于阴影计算的坐标
			};
			
			// 顶点着色器：计算所需的中间数据
			v2f vert(a2v v) {
				v2f o;
				// 将顶点转换到裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// 计算世界空间的法线方向
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				// 计算世界空间的顶点位置
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				// 计算从观察者到顶点的方向（世界空间）
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				
				// 使用 refract 函数计算折射方向
				// refract(入射向量, 法线向量, 折射率)
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
				
				// 传递阴影坐标
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			// 片元着色器：计算最终的像素颜色
			fixed4 frag(v2f i) : SV_Target {
				// 归一化法线、光照方向和观察方向
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				
				// 环境光颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// 漫反射光照计算：光源颜色 * 物体颜色 * 法线与光照方向的点积
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
				
				// 使用折射方向从 Cubemap 中采样颜色
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
				
				// 计算光照衰减
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				// 将漫反射和折射颜色按比例混合
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
				
				// 返回最终颜色（带 alpha 通道）
				return fixed4(color, 1.0);
			}
			
			ENDCG
		}
	}
	
	// 当不支持该 Shader 时回退到其他 Shader
	FallBack "Reflective/VertexLit"
}
