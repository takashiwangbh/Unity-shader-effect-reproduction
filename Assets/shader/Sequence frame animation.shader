Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" {
	Properties {
		// 定义着色器的属性
		_Color ("Color Tint", Color) = (1, 1, 1, 1) // 颜色叠加，用于调整纹理颜色
		_MainTex ("Image Sequence", 2D) = "white" {} // 用于播放动画的图片序列纹理
    	_HorizontalAmount ("Horizontal Amount", Float) = 4 // 横向切分的数量
    	_VerticalAmount ("Vertical Amount", Float) = 4 // 纵向切分的数量
    	_Speed ("Speed", Range(1, 100)) = 30 // 动画播放速度
	}
	SubShader {
		Tags {
			// 设置渲染队列和属性，确保透明对象正确渲染
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent"
		}
		
		Pass {
			Tags { "LightMode"="ForwardBase" } // 使用正向渲染路径
			
			ZWrite Off // 关闭深度写入，因为是透明对象
			Blend SrcAlpha OneMinusSrcAlpha // 设置透明混合模式
			
			CGPROGRAM
			
			#pragma vertex vert // 定义顶点着色器
			#pragma fragment frag // 定义片段着色器
			
			#include "UnityCG.cginc" // 引入 Unity 常用的工具函数库
			
			// 声明属性和变量
			fixed4 _Color; // 颜色叠加属性
			sampler2D _MainTex; // 图片序列纹理
			float4 _MainTex_ST; // 纹理的缩放和偏移
			float _HorizontalAmount; // 横向切分的数量
			float _VerticalAmount; // 纵向切分的数量
			float _Speed; // 动画播放速度
			
			// 顶点输入数据结构
			struct a2v {  
			    float4 vertex : POSITION; // 顶点位置
			    float2 texcoord : TEXCOORD0; // 顶点的纹理坐标
			};  
			
			// 顶点着色器输出数据结构
			struct v2f {  
			    float4 pos : SV_POSITION; // 裁剪空间位置
			    float2 uv : TEXCOORD0; // 纹理坐标
			};  
			
			// 顶点着色器
			v2f vert (a2v v) {  
				v2f o;  
				// 转换到裁剪空间坐标
				o.pos = UnityObjectToClipPos(v.vertex);  
				// 转换纹理坐标
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
				return o;
			}  
			
			// 片段着色器
			fixed4 frag (v2f i) : SV_Target {
				// 根据当前时间计算当前帧
				float time = floor(_Time.y * _Speed); // 使用 `_Time.y` 获取全局时间
				float row = floor(time / _HorizontalAmount); // 当前帧在第几行
				float column = time - row * _HorizontalAmount; // 当前帧在第几列
				
				// 计算对应的 UV 坐标
				half2 uv = i.uv + half2(column, -row); // 偏移原始 UV
				uv.x /= _HorizontalAmount; // 根据横向切分调整 UV
				uv.y /= _VerticalAmount; // 根据纵向切分调整 UV
				
				// 采样当前帧的颜色
				fixed4 c = tex2D(_MainTex, uv);
				c.rgb *= _Color; // 应用颜色叠加效果
				
				return c; // 返回最终颜色
			}
			
			ENDCG
		}  
	}
	// 如果设备不支持，回退到默认透明着色器
	FallBack "Transparent/VertexLit"
}
