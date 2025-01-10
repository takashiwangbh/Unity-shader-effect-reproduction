/*
Shader 名称: Noise-WaterWave
用途: 模拟动态水波纹效果，结合法线扰动、折射和反射来创建逼真的水面效果。

功能说明:
1. **水波扰动**:
   - 使用噪声纹理控制水面的动态法线变化，实现水波效果。
   - 控制波动的速度和幅度。

2. **折射效果**:
   - 使用屏幕抓取纹理模拟光线穿过水面的折射现象。
   - 根据法线扰动计算水面折射后的图像偏移。

3. **反射效果**:
   - 使用环境立方体贴图模拟水面的反射。
   - 结合法线和视角方向计算反射颜色。

4. **菲涅尔效应**:
   - 根据观察角度混合反射和折射，实现真实的水面外观。

*/

Shader "Noise-WaterWave" {
	Properties {
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1) // 主颜色，用于整体的颜色调节
		_MainTex ("Base (RGB)", 2D) = "white" {} // 基础颜色纹理
		_WaveMap ("Wave Map", 2D) = "bump" {} // 水波扰动的法线贴图
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {} // 环境立方体贴图
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01 // 水波横向速度
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01 // 水波纵向速度
		_Distortion ("Distortion", Range(0, 100)) = 10 // 水波扰动强度
	}
	SubShader {
		// 定义渲染顺序为透明队列，其他物体需先绘制
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// 抓取屏幕作为折射纹理
		GrabPass { "_RefractionTex" }
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			// 参数声明
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			
			// 顶点着色器
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION; // 顶点位置
				float4 scrPos : TEXCOORD0; // 屏幕空间坐标
				float4 uv : TEXCOORD1; // UV 坐标
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex); // 转换顶点位置到裁剪空间
				o.scrPos = ComputeGrabScreenPos(o.pos); // 计算屏幕空间坐标
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex); // 主纹理 UV
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap); // 波纹法线贴图 UV
				
				// 计算世界空间的切线、法线和副法线
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				// 存储切线到世界的变换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			// 像素着色器
			fixed4 frag(v2f i) : SV_Target {
				// 计算视线方向
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// 计算水波扰动
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2); // 组合扰动法线
				
				// 根据扰动计算 UV 偏移
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// 计算反射方向
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
				fixed3 reflDir = reflect(-viewDir, bump);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
				
				// 菲涅尔效应
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	// 不渲染阴影
	FallBack Off
}
