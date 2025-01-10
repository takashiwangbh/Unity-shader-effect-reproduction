/*
Shader 名称: Dissolve (溶解特效)
用途: 实现物体逐渐溶解或消失的特效，同时在溶解边界提供燃烧线条的动画过渡效果。

功能说明:
1. **溶解控制**:
   - 通过 `_BurnAmount` 参数控制溶解的程度。
   - 使用 `_BurnMap` 纹理定义溶解效果的图案。

2. **燃烧线条**:
   - 燃烧边界的宽度由 `_LineWidth` 决定。
   - 燃烧线条颜色通过 `_BurnFirstColor` 和 `_BurnSecondColor` 进行渐变。

3. **光照支持**:
   - 包括环境光和漫反射光的计算。
   - 支持 Unity 的前向光照模型和阴影投射。
  
*/

Shader "Unity Shaders Book/Chapter 15/Dissolve" {
    Properties {
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0 // 溶解程度控制，从0到1，1表示完全溶解。
        _LineWidth ("Burn Line Width", Range(0.0, 0.2)) = 0.1 // 燃烧线条的宽度。
        _MainTex ("Base (RGB)", 2D) = "white" {} // 物体的基础纹理。
        _BumpMap ("Normal Map", 2D) = "bump" {} // 法线贴图，用于增强表面细节的光照效果。
        _BurnFirstColor ("Burn First Color", Color) = (1, 0, 0, 1) // 燃烧线条颜色的起始颜色。
        _BurnSecondColor ("Burn Second Color", Color) = (1, 0, 0, 1) // 燃烧线条颜色的结束颜色。
        _BurnMap ("Burn Map", 2D) = "white" {} // 定义溶解图案的纹理。
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"} // 定义渲染类型和队列。

        Pass {
            Tags { "LightMode"="ForwardBase" } // 支持 Unity 的前向光照模型。
            Cull Off // 关闭剔除，渲染物体的正面和背面。

            CGPROGRAM

            #include "Lighting.cginc" // 包含 Unity 的光照函数库。
            #include "AutoLight.cginc" // 包含 Unity 自动光照处理的相关函数。

            #pragma multi_compile_fwdbase // 支持基础光照模式的多重编译。
            #pragma vertex vert // 指定顶点着色器。
            #pragma fragment frag // 指定片段着色器。

            fixed _BurnAmount; // 溶解进度控制。
            fixed _LineWidth; // 燃烧线条宽度控制。
            sampler2D _MainTex; // 基础纹理。
            sampler2D _BumpMap; // 法线贴图。
            fixed4 _BurnFirstColor; // 燃烧线条起始颜色。
            fixed4 _BurnSecondColor; // 燃烧线条结束颜色。
            sampler2D _BurnMap; // 溶解纹理。

            float4 _MainTex_ST; // 基础纹理的 UV 变换。
            float4 _BumpMap_ST; // 法线贴图的 UV 变换。
            float4 _BurnMap_ST; // 溶解纹理的 UV 变换。

            struct a2v {
                float4 vertex : POSITION; // 顶点位置。
                float3 normal : NORMAL; // 顶点法线。
                float4 tangent : TANGENT; // 顶点切线，用于法线贴图。
                float4 texcoord : TEXCOORD0; // 顶点的 UV 坐标。
            };

            struct v2f {
                float4 pos : SV_POSITION; // 顶点投影后的屏幕位置。
                float2 uvMainTex : TEXCOORD0; // 基础纹理的 UV 坐标。
                float2 uvBumpMap : TEXCOORD1; // 法线贴图的 UV 坐标。
                float2 uvBurnMap : TEXCOORD2; // 溶解纹理的 UV 坐标。
                float3 lightDir : TEXCOORD3; // 光源方向。
                float3 worldPos : TEXCOORD4; // 世界空间的顶点位置。
                SHADOW_COORDS(5) // 阴影坐标。
            };

            // 顶点着色器：计算各项数据并传递给片段着色器。
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 转换到投影空间。

                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex); // 计算基础纹理的 UV。
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap); // 计算法线贴图的 UV。
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap); // 计算溶解纹理的 UV。

                TANGENT_SPACE_ROTATION; // 计算切线空间的旋转矩阵。
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz; // 计算切线空间的光照方向。

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // 转换到世界空间。

                TRANSFER_SHADOW(o); // 计算阴影信息。

                return o;
            }

            // 片段着色器：实现溶解效果的颜色计算。
            fixed4 frag(v2f i) : SV_Target {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb; // 从溶解纹理中取样。

                clip(burn.r - _BurnAmount); // 根据 Burn Map 和 Burn Amount 控制像素是否渲染。

                float3 tangentLightDir = normalize(i.lightDir); // 归一化切线空间的光照方向。
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap)); // 解码法线。

                fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb; // 从基础纹理中取样颜色。

                // 环境光计算
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 漫反射光计算
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 燃烧线条颜色计算
                fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
                fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t); // 线条颜色渐变。
                burnColor = pow(burnColor, 5); // 加强颜色对比度。

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); // 光照衰减。
                fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));

                return fixed4(finalColor, 1); // 返回最终颜色。
            }

            ENDCG
        }
    }
    FallBack "Diffuse" // 当不支持此 Shader 时，使用 Diffuse 着色器。
}
