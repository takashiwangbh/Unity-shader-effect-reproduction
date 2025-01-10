/*
这个脚本用于实现屏幕后处理的边缘检测效果。
通过自定义 Shader，对图像的边缘进行检测，并允许用户调整边缘的显示方式，
如边缘透明度、边缘颜色和背景颜色。

*/

using UnityEngine;
using System.Collections;

public class EdgeDetection : PostEffectsBase {

    // 引用用于边缘检测的 Shader
    public Shader edgeDetectShader;

    // 用于存储和应用 Shader 的材质
    private Material edgeDetectMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }  
    }

    // 边缘显示的强度范围（0 表示完全显示背景，1 表示只显示边缘）
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;

    // 边缘的颜色
    public Color edgeColor = Color.black;

    // 背景的颜色
    public Color backgroundColor = Color.white;

    // 屏后处理方法，用于渲染边缘检测后的图像
    void OnRenderImage (RenderTexture src, RenderTexture dest) {
        // 检查材质是否可用
        if (material != null) {
            // 设置 Shader 参数：边缘强度、边缘颜色、背景颜色
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            // 使用材质将源纹理 (src) 渲染到目标纹理 (dest)
            Graphics.Blit(src, dest, material);
        } else {
            // 如果材质不可用，直接复制原始纹理
            Graphics.Blit(src, dest);
        }
    }
}