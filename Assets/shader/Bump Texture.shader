Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space" {
	Properties {
		// 控制整体材质颜色的属性
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		// 纹理属性，主纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		// 法线贴图的纹理属性
		_BumpMap ("Normal Map", 2D) = "bump" {}
		// 控制法线贴图的缩放强度
		_BumpScale ("Bump Scale", Float) = 1.0
		// 镜面反射的颜色属性
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		// 镜面高光的范围
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert // 顶点着色器函数
			#pragma fragment frag // 片段着色器函数
			
			#include "Lighting.cginc" // 引入 Unity 的光照函数库
			
			// 定义材质相关属性的变量
			fixed4 _Color;
			sampler2D _MainTex; // 主纹理采样器
			float4 _MainTex_ST; // 主纹理的缩放与偏移
			sampler2D _BumpMap; // 法线贴图采样器
			float4 _BumpMap_ST; // 法线贴图的缩放与偏移
			float _BumpScale; // 法线缩放强度
			fixed4 _Specular;
			float _Gloss;
			
			// 输入顶点数据
			struct a2v {
				float4 vertex : POSITION; // 顶点位置
				float3 normal : NORMAL; // 顶点法线
				float4 tangent : TANGENT; // 切线信息
				float4 texcoord : TEXCOORD0; // 纹理坐标
			};
			
			// 传递到片段着色器的数据
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间位置
				float4 uv : TEXCOORD0; // 主纹理和法线纹理坐标
				float3 lightDir: TEXCOORD1; // 切线空间的光方向
				float3 viewDir : TEXCOORD2; // 切线空间的视角方向
			};

			// 顶点着色器
			v2f vert(a2v v) {
				v2f o;
				// 转换顶点到裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// 计算主纹理和法线贴图的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				// 构建从切线空间到世界空间的变换矩阵
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				// 构建从世界空间到切线空间的变换矩阵
				float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);

				// 将光方向和视角方向从世界空间转换到切线空间
				o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
				o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));
				
				return o;
			}
			
			// 片段着色器
			fixed4 frag(v2f i) : SV_Target {
				// 规范化光方向和视角方向
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				
				// 从法线贴图中获取纹理数据
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				
				// 解压法线贴图数据到切线空间的法线
				tangentNormal = UnpackNormal(packedNormal);
				// 应用法线缩放强度
				tangentNormal.xy *= _BumpScale;
				// 重新计算 z 分量，确保法线单位化
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				// 获取主纹理颜色并乘以整体颜色调节
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				// 计算环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				// 计算漫反射光
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				// 计算镜面高光
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				
				// 返回最终颜色，合成环境光、漫反射和高光
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	// 如果当前设备不支持此 Shader，使用默认镜面 Shader
	FallBack "Specular"
}
