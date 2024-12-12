Shader "Unity Shaders Book/Chapter 9/Forward Rendering" {
	Properties {
		// 定义表面颜色、镜面反射颜色以及光泽度
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)       // 漫反射颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)     // 镜面反射颜色
		_Gloss ("Gloss", Range(8.0, 256)) = 20          // 光泽度（影响镜面反射的高光大小）
	}
	SubShader {
		// 标签定义为不透明物体
		Tags { "RenderType"="Opaque" }
		
		Pass {
			// 用于环境光和第一个像素光（平行光）的渲染通道
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			// 编译环境光和第一个像素光所需的多个代码路径
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert               // 指定顶点着色器函数
			#pragma fragment frag             // 指定片段着色器函数
			
			#include "Lighting.cginc"         // 引入内置光照计算函数
			
			// 定义传入的材质属性
			fixed4 _Diffuse;                  // 漫反射颜色
			fixed4 _Specular;                 // 镜面反射颜色
			float _Gloss;                     // 光泽度
			
			// 定义顶点输入结构
			struct a2v {
				float4 vertex : POSITION;     // 顶点坐标
				float3 normal : NORMAL;       // 法线
			};
			
			// 定义顶点到片段的数据结构
			struct v2f {
				float4 pos : SV_POSITION;     // 裁剪空间中的顶点位置
				float3 worldNormal : TEXCOORD0; // 世界空间的法线
				float3 worldPos : TEXCOORD1;  // 世界空间的顶点位置
			};
			
			// 顶点着色器
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);  // 转换到裁剪空间
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal); // 转换到世界空间法线
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 转换到世界空间顶点位置
				
				return o;
			}
			
			// 片段着色器
			fixed4 frag(v2f i) : SV_Target {
				// 归一化世界法线
				fixed3 worldNormal = normalize(i.worldNormal);
				// 归一化平行光方向
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// 计算环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
			 	// 计算漫反射光照
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	// 计算镜面高光
			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); // 视角方向
			 	fixed3 halfDir = normalize(worldLightDir + viewDir); // 半程向量
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				// 设置光衰减为 1.0（仅对第一个光源适用）
				fixed atten = 1.0;
				
				// 返回最终颜色
				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	
		Pass {
			// 用于额外像素光的渲染通道
			Tags { "LightMode"="ForwardAdd" }
			
			// 累加混合模式
			Blend One One
		
			CGPROGRAM
			
			// 编译额外像素光的代码路径
			#pragma multi_compile_fwdadd
			
			#pragma vertex vert               // 顶点着色器
			#pragma fragment frag             // 片段着色器
			
			#include "Lighting.cginc"         // 内置光照函数
			#include "AutoLight.cginc"        // 自动光衰减函数
			
			// 定义材质属性
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			// 顶点输入结构
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			// 顶点到片段的数据结构
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			// 顶点着色器
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}
			
			// 片段着色器
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				
				#ifdef USING_DIRECTIONAL_LIGHT
					// 定向光的方向
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					// 点光源或聚光灯的方向
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				// 漫反射计算
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				// 镜面反射计算
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				// 根据光源类型计算光衰减
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0; // 定向光没有光衰减
				#else
					#if defined (POINT)
				        // 点光源衰减
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        // 聚光灯衰减
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif

				// 返回累加的颜色
				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	// 回退到内置的高光着色器
	FallBack "Specular"
}
