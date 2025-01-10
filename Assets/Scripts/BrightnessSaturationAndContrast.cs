/*
这个脚本用于实现屏幕后处理效果中的亮度、饱和度和对比度调整。
它通过自定义的 Shader 来处理图像，并允许开发者在 Unity Inspector 中
调整亮度、饱和度和对比度的数值，从而实时影响画面效果。
*/

using UnityEngine;
using System.Collections;

public class BrightnessSaturationAndContrast : PostEffectsBase {

    // 引用一个自定义 Shader，用于调整亮度、饱和度和对比度
    public Shader briSatConShader;

    // 基于 Shader 创建的材质，用于应用屏后处理效果
    private Material briSatConMaterial;

    // 延迟加载材质，当需要时自动检查 Shader 并创建材质
    public Material material {  
        get {
            // 检查 Shader 是否支持并创建材质
            briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
            return briSatConMaterial;
        }  
    }

    // 亮度调整范围（从 0.0 到 3.0），默认值为 1.0
    [Range(0.0f, 3.0f)]
    public float brightness = 1.0f;

    // 饱和度调整范围（从 0.0 到 3.0），默认值为 1.0
    [Range(0.0f, 3.0f)]
    public float saturation = 1.0f;

    // 对比度调整范围（从 0.0 到 3.0），默认值为 1.0
    [Range(0.0f, 3.0f)]
    public float contrast = 1.0f;

    // Unity 中的屏后处理方法，在摄像机渲染完成后调用
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        // 检查材质是否可用
        if (material != null) {
            // 将亮度、饱和度和对比度的值传递给 Shader
            material.SetFloat("_Brightness", brightness);
            material.SetFloat("_Saturation", saturation);
            material.SetFloat("_Contrast", contrast);

            // 使用材质将源纹理 (src) 渲染到目标纹理 (dest)
            Graphics.Blit(src, dest, material);
        } else {
            // 如果材质不可用，直接将源纹理复制到目标纹理
            Graphics.Blit(src, dest);
        }
    }
}