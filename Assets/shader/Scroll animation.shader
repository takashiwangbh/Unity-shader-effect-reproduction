Shader "Unity Shaders Book/Chapter 11/Scrolling Background" {
	Properties {
		// 定义属性，用于在材质界面调整
		_MainTex ("Base Layer (RGB)", 2D) = "white" {} // 基础纹理（第一层纹理）
		_DetailTex ("2nd Layer (RGB)", 2D) = "white" {} // 第二层叠加纹理
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0 // 基础纹理的水平滚动速度
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0 // 第二层纹理的水平滚动速度
		_Multiplier ("Layer Multiplier", Float) = 1 // 调节最终输出亮度的倍增因子
	}
	SubShader {
		Tags { 
			"RenderType"="Opaque" // 渲染类型为不透明
			"Queue"="Geometry" // 渲染队列为几何体（默认）
		}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" } // 使用正向渲染的基本通道
			
			CGPROGRAM
			
			#pragma vertex vert // 指定顶点着色器
			#pragma fragment frag // 指定片段着色器
			
			#include "UnityCG.cginc" // 包含 Unity 的常用工具函数
			
			// 声明纹理和属性
			sampler2D _MainTex; // 基础纹理采样器
			sampler2D _DetailTex; // 第二层纹理采样器
			float4 _MainTex_ST; // 基础纹理的缩放和偏移
			float4 _DetailTex_ST; // 第二层纹理的缩放和偏移
			float _ScrollX; // 基础层水平滚动速度
			float _Scroll2X; // 第二层水平滚动速度
			float _Multiplier; // 输出亮度倍增因子
			
			// 顶点输入结构
			struct a2v {
				float4 vertex : POSITION; // 顶点位置
				float4 texcoord : TEXCOORD0; // 顶点的纹理坐标
			};
			
			// 顶点输出结构
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间位置
				float4 uv : TEXCOORD0; // 第一层和第二层纹理的 UV 坐标
			};
			
			// 顶点着色器
			v2f vert (a2v v) {
				v2f o;
				// 将模型空间位置转换为裁剪空间位置
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// 计算第一层纹理的滚动 UV 坐标
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) 
						  + frac(float2(_ScrollX, 0.0) * _Time.y); 
				// 使用 `frac` 确保滚动的 UV 在 [0, 1] 范围内循环

				// 计算第二层纹理的滚动 UV 坐标
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) 
						  + frac(float2(_Scroll2X, 0.0) * _Time.y);

				return o; // 输出数据给片段着色器
			}
			
			// 片段着色器
			fixed4 frag (v2f i) : SV_Target {
				// 使用第一层的 UV 坐标采样基础纹理颜色
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				// 使用第二层的 UV 坐标采样叠加纹理颜色
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				
				// 将两个纹理叠加，使用第二层纹理的 Alpha 通道作为插值因子
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				// 使用倍增因子调整最终颜色亮度
				c.rgb *= _Multiplier;

				return c; // 返回计算后的颜色
			}
			
			ENDCG
		}
	}
	// 如果硬件不支持该着色器，回退到 VertexLit 着色器
	FallBack "VertexLit"
}
