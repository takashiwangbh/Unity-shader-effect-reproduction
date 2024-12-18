// Shader 实现 Billboard（广告牌效果），用于使平面始终面向摄像机。
// 支持垂直约束，可选择让平面的垂直方向固定或完全自由旋转。
Shader "Unity Shaders Book/Chapter 11/Billboard" {
	Properties {
		// 主纹理，用于定义广告牌的表面纹理
		_MainTex ("Main Tex", 2D) = "white" {}
		// 颜色调节，用于整体调整纹理的颜色
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		// 垂直约束选项，值为1时垂直方向固定，值为0时自由旋转
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
	}
	SubShader {
		// 禁用批处理，因为顶点动画导致每个对象需要单独处理
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			// 关闭深度写入，启用Alpha混合
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			// 关闭剔除，确保双面可见
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert // 顶点着色器
			#pragma fragment frag // 片元着色器
			
			#include "Lighting.cginc" // 包含Unity光照函数库
			
			// 定义Shader中的属性
			sampler2D _MainTex; // 主纹理
			float4 _MainTex_ST; // 主纹理的UV变换参数
			fixed4 _Color; // 颜色调节
			fixed _VerticalBillboarding; // 垂直约束控制变量
			
			// 输入结构：顶点着色器接收的输入数据
			struct a2v {
				float4 vertex : POSITION; // 顶点位置
				float4 texcoord : TEXCOORD0; // 顶点纹理坐标
			};
			
			// 输出结构：从顶点着色器传递到片元着色器的数据
			struct v2f {
				float4 pos : SV_POSITION; // 裁剪空间中的顶点位置
				float2 uv : TEXCOORD0; // 纹理坐标
			};
			
			// 顶点着色器
			v2f vert (a2v v) {
				v2f o; // 定义输出数据
				
				// 假设物体空间中的广告牌中心点固定在 (0, 0, 0)
				float3 center = float3(0, 0, 0);
				// 计算摄像机在物体空间中的位置
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				
				// 计算广告牌面向摄像机的方向向量
				float3 normalDir = viewer - center;
				// 根据 _VerticalBillboarding 调整方向向量的 y 分量
				// 如果 _VerticalBillboarding = 1，则保留垂直分量（完全自由旋转）
				// 如果 _VerticalBillboarding = 0，则固定垂直方向（y分量为0）
				normalDir.y = normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir); // 归一化方向向量
				
				// 确定上方向（upDir），如果 normalDir 接近竖直方向，则 upDir 为前方向（z轴方向）
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				// 通过叉积计算右方向（rightDir）
				float3 rightDir = normalize(cross(upDir, normalDir));
				// 再次通过叉积重新计算上方向，确保正交
				upDir = normalize(cross(normalDir, rightDir));
				
				// 使用 rightDir、upDir 和 normalDir 旋转广告牌顶点
				float3 centerOffs = v.vertex.xyz - center; // 计算顶点相对于中心点的偏移量
				float3 localPos = center 
					+ rightDir * centerOffs.x // 根据x偏移调整到正确的右方向位置
					+ upDir * centerOffs.y   // 根据y偏移调整到正确的上方向位置
					+ normalDir * centerOffs.z; // z方向的偏移保持不变
              
				// 将计算后的本地坐标转换到裁剪空间
				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				// 转换纹理坐标
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o; // 返回输出数据
			}
			
			// 片元着色器
			fixed4 frag (v2f i) : SV_Target {
				// 从纹理中采样颜色
				fixed4 c = tex2D(_MainTex, i.uv);
				// 将采样颜色与颜色调节混合
				c.rgb *= _Color.rgb;
				
				// 返回最终的片元颜色
				return c;
			}
			
			ENDCG
		}
	} 
	// 设置回退Shader，用于低端设备的兼容性
	FallBack "Transparent/VertexLit"
}
