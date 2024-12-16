Shader "Unity Shaders Book/Chapter 5/False Color" { // 定义了一个名为 "False Color" 的着色器
    SubShader { // 一个子着色器
        Pass { // 着色器的一个 Pass
            CGPROGRAM // 开始编写 CG 代码
            
            #pragma vertex vert // 指定顶点着色器函数为 vert
            #pragma fragment frag // 指定片段着色器函数为 frag
            
            #include "UnityCG.cginc" // 包含 Unity 的常用 CG 工具函数
            
            struct v2f { // 定义顶点到片段的结构体
                float4 pos : SV_POSITION; // 顶点的屏幕坐标
                fixed4 color : COLOR0; // 输出到片段的颜色
            };
            
            v2f vert(appdata_full v) { // 顶点着色器
                v2f o; // 定义一个输出结构体
                o.pos = UnityObjectToClipPos(v.vertex); // 将模型空间的顶点转换为裁剪空间坐标
                
                // 可视化法线 (Normal)
                o.color = fixed4(v.normal * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);
                // 将法线值从 (-1,1) 转换为 (0,1)，以便用颜色显示
                
                // 可视化切线 (Tangent)
                o.color = fixed4(v.tangent.xyz * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);
                // 同样对切线进行归一化和偏移，用颜色展示
                
                // 可视化双切线 (Binormal)
                fixed3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
                // 计算双切线，通过法线和切线的叉积计算，乘以切线的 w 值
                o.color = fixed4(binormal * 0.5 + fixed3(0.5, 0.5, 0.5), 1.0);
                // 对双切线归一化并用颜色显示
                
                // 可视化第一套纹理坐标 (UV1)
                o.color = fixed4(v.texcoord.xy, 0.0, 1.0);
                // 使用第一套 UV 坐标，将其 XY 直接映射为颜色的 RG 分量
                
                // 可视化第二套纹理坐标 (UV2)
                o.color = fixed4(v.texcoord1.xy, 0.0, 1.0);
                // 使用第二套 UV 坐标，映射为颜色
                
                // 可视化第一套纹理坐标的分数部分
                o.color = frac(v.texcoord); // frac() 提取小数部分
                if (any(saturate(v.texcoord) - v.texcoord)) { 
                    // 检查 UV 是否超出 (0,1) 范围，若超出，则标记
                    o.color.b = 0.5; // 蓝色通道设为 0.5 表示标记
                }
                o.color.a = 1.0; // 设置透明度为 1
                
                // 可视化第二套纹理坐标的分数部分
                o.color = frac(v.texcoord1); // 同理提取第二套 UV 的小数部分
                if (any(saturate(v.texcoord1) - v.texcoord1)) { 
                    // 检查第二套 UV 是否超出范围
                    o.color.b = 0.5;
                }
                o.color.a = 1.0;
                
                // 可视化顶点颜色
                // o.color = v.color; // 如果需要可视化模型的顶点颜色，取消注释
                
                return o; // 返回计算好的数据
            }
            
            fixed4 frag(v2f i) : SV_Target { // 片段着色器
                return i.color; // 输出顶点着色器计算的颜色
            }
            
            ENDCG // 结束 CG 代码
        }
    }
}
