Shader "Unity Shaders Book/Chapter 6/Specular Pixel-Level" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1) // 漫反射颜色属性，用于定义物体的基本颜色。
		_Specular ("Specular", Color) = (1, 1, 1, 1) // 镜面反射颜色属性，用于控制高光的颜色和强度。
		_Gloss ("Gloss", Range(8.0, 256)) = 20 // 光泽度属性，决定高光的锐度（值越高，越集中）。
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" } // 指定光照模式为ForwardBase（前向渲染）。
		
			CGPROGRAM
			
			#pragma vertex vert // 指定顶点着色器函数。
			#pragma fragment frag // 指定片段着色器函数。

			#include "Lighting.cginc" // 引入Unity光照计算的库文件，提供基本光照公式。
			
			// 定义漫反射颜色、镜面反射颜色以及光泽度的全局变量。
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			// 顶点输入结构体，接收模型的顶点信息。
			struct a2v {
				float4 vertex : POSITION; // 顶点坐标
				float3 normal : NORMAL;   // 顶点法线
			};
			
			// 顶点输出结构体，用于传递到片段着色器。
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间的顶点坐标，用于渲染。
				float3 worldNormal : TEXCOORD0; // 世界空间中的法线，用于光照计算。
				float3 worldPos : TEXCOORD1;    // 世界空间中的顶点位置，用于反射和观察方向计算。
			};
			
			v2f vert(a2v v) {
				v2f o;
				// 将模型空间中的顶点位置转换到裁剪空间（渲染所需的坐标）。
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// 将模型空间的法线转换到世界空间，用于后续的光照计算。
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				
				// 将模型空间的顶点坐标转换到世界空间，用于计算视角方向和反射方向。
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o; // 返回顶点着色器的输出数据。
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// 获取环境光分量，模拟全局光照对物体的影响。
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// 对法线进行归一化，确保方向向量的正确性。
				fixed3 worldNormal = normalize(i.worldNormal);
				// 获取世界空间中的光源方向。
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// 计算漫反射分量，使用光源颜色、漫反射颜色以及法线和光照方向的点积。
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				
				// 计算反射方向，用于模拟镜面反射效果。
				fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
				// 计算观察方向（从顶点位置指向相机的位置）。
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				// 使用镜面反射公式计算高光部分，点积的结果提升到光泽度的指数。
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
				
				// 最终颜色由环境光、漫反射和镜面反射组合而成。
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular" // 设置备用Shader，当当前设备不支持时使用。
}
