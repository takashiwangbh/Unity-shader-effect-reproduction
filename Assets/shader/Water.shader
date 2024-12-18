// 水面效果的Shader，用于创建具有动态波动的透明水面材质
Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		// 主纹理，用于定义水面的基本纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		// 水面颜色调整，用于控制整体颜色
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		// 波动的幅度，影响波动的强弱
		_Magnitude ("Distortion Magnitude", Float) = 1
 		// 波动的频率，决定波动的快慢
 		_Frequency ("Distortion Frequency", Float) = 1
 		// 波动的波长倒数，控制波的疏密
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		// 波动的移动速度
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {
		// 禁用批处理，因为顶点动画会导致实例化数据不同
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			// 使用透明材质的渲染设置
			Tags { "LightMode"="ForwardBase" }
			
			// 禁用深度写入，确保透明效果
			ZWrite Off
			// 设定Alpha混合模式，用于实现透明度
			Blend SrcAlpha OneMinusSrcAlpha
			// 不剔除背面，用于确保双面都能显示
			Cull Off
			
			CGPROGRAM  
			#pragma vertex vert // 顶点着色器
			#pragma fragment frag // 像素着色器
			
			#include "UnityCG.cginc" // 包含Unity的通用工具函数
			
			// 定义传入的材质属性
			sampler2D _MainTex; // 主纹理
			float4 _MainTex_ST; // 主纹理的UV变换参数
			fixed4 _Color; // 水的颜色
			float _Magnitude; // 波动幅度
			float _Frequency; // 波动频率
			float _InvWaveLength; // 波长倒数
			float _Speed; // 波动移动速度
			
			// 定义顶点输入结构
			struct a2v {
				float4 vertex : POSITION; // 顶点位置
				float4 texcoord : TEXCOORD0; // 顶点纹理坐标
			};
			
			// 定义传递给片元着色器的数据结构
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间中的顶点位置
				float2 uv : TEXCOORD0; // 纹理坐标
			};
			
			// 顶点着色器
			v2f vert(a2v v) {
				v2f o; // 定义输出数据
				
				// 定义偏移量，主要影响顶点的x方向
				float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0); // y和z方向无偏移
				offset.x = sin(
					_Frequency * _Time.y // 时间相关的波动
					+ v.vertex.x * _InvWaveLength // x方向的波动
					+ v.vertex.y * _InvWaveLength // y方向的波动
					+ v.vertex.z * _InvWaveLength // z方向的波动
				) * _Magnitude; // 乘以幅度控制强弱
				
				// 计算裁剪空间中的顶点位置，加入偏移实现波动效果
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				// 转换纹理坐标，并添加时间相关的偏移以模拟水流
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv += float2(0.0, _Time.y * _Speed);
				
				return o; // 返回处理后的顶点数据
			}
			
			// 片元着色器
			fixed4 frag(v2f i) : SV_Target {
				// 从纹理采样颜色
				fixed4 c = tex2D(_MainTex, i.uv);
				// 将纹理颜色乘以全局颜色调节，调整水面效果
				c.rgb *= _Color.rgb;
				
				// 返回处理后的像素颜色
				return c;
			} 
			
			ENDCG
		}
	}
	// 回退Shader设置，使用透明的顶点光照
	FallBack "Transparent/VertexLit"
}
