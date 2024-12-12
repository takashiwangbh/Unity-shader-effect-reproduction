Shader "Unity Shaders Book/Chapter 9/Alpha Test With Shadow" {
	// Shader 名称，便于在 Unity 中选择
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1) // 用于控制材质颜色的属性
		_MainTex ("Main Tex", 2D) = "white" {} // 主纹理
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5 // Alpha 测试的阈值
	}
	SubShader {
		// 定义渲染的具体规则
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		// 渲染队列设为 AlphaTest，并且忽略投影器影响。RenderType 表明透明剪裁类型

		Pass {
			Tags { "LightMode"="ForwardBase" } 
			// 使用 ForwardBase 渲染模式（用于处理基本光源）

			Cull Off
			// 关闭面剔除（显示所有面，包括背面）

			CGPROGRAM
			// 开始定义 GPU 程序（Vertex 和 Fragment Shader）

			#pragma multi_compile_fwdbase
			// 启用基础光照的多编译选项

			#pragma vertex vert
			#pragma fragment frag
			// 指定顶点着色器和片段着色器

			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			// 引入 Unity 提供的光照库

			fixed4 _Color; // 属性中定义的颜色
			sampler2D _MainTex; // 主纹理采样器
			float4 _MainTex_ST; // 纹理 UV 变换参数
			fixed _Cutoff; // Alpha 测试的阈值

			struct a2v {
				float4 vertex : POSITION; // 顶点坐标
				float3 normal : NORMAL; // 顶点法线
				float4 texcoord : TEXCOORD0; // 顶点 UV 坐标
			};
			
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间坐标
				float3 worldNormal : TEXCOORD0; // 世界空间法线
				float3 worldPos : TEXCOORD1; // 世界空间位置
				float2 uv : TEXCOORD2; // UV 坐标
				SHADOW_COORDS(3) // 用于存储阴影贴图的坐标
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
			 	// 将顶点从对象空间变换到裁剪空间

			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	// 将法线从对象空间变换到世界空间

			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	// 将顶点从对象空间变换到世界空间

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	// 对 UV 坐标进行纹理变换

			 	TRANSFER_SHADOW(o);
			 	// 将阴影相关坐标传递给片段着色器

			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				// 归一化世界空间法线

				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				// 计算世界空间中的光源方向

				fixed4 texColor = tex2D(_MainTex, i.uv);
				// 从主纹理中采样颜色

				clip (texColor.a - _Cutoff);
				// Alpha 测试，丢弃 Alpha 值小于 Cutoff 的像素

				fixed3 albedo = texColor.rgb * _Color.rgb;
				// 计算表面反照率颜色（纹理颜色与 Tint 色相乘）

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				// 环境光照（全局环境光 * 反照率）

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				// 漫反射光照（光源颜色 * 反照率 * 光照角度）

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				// 计算光照衰减（包括阴影）

				return fixed4(ambient + diffuse * atten, 1.0);
				// 返回最终颜色（环境光 + 漫反射 * 衰减）
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/Cutout/VertexLit"
	// 当 Shader 不被支持时，回退到内置的 Transparent/Cutout/VertexLit Shader
}
