/*
这个脚本实现了基于法线和深度的边缘检测效果。
通过获取场景的法线和深度纹理，检测像素间的变化，
从而提取边缘信息。可以调整边缘强度、检测灵敏度和采样距离来控制最终的效果。
*/

using UnityEngine;
using System.Collections;

public class EdgeDetectNormalsAndDepth : PostEffectsBase {

    // 边缘检测的 Shader
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }  
    }

    // 边缘显示强度，0 表示仅显示边缘，1 表示保留原始场景
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;

    // 边缘颜色
    public Color edgeColor = Color.black;

    // 背景颜色（非边缘区域）
    public Color backgroundColor = Color.white;

    // 采样距离，用于计算像素差异
    public float sampleDistance = 1.0f;

    // 深度检测灵敏度
    public float sensitivityDepth = 1.0f;

    // 法线检测灵敏度
    public float sensitivityNormals = 1.0f;
    
    // 启用时启用深度法线纹理
    void OnEnable() {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    // 在后处理阶段渲染图像
    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            // 设置 Shader 参数
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

            // 使用材质处理源纹理并渲染到目标纹理
            Graphics.Blit(src, dest, material);
        } else {
            // 如果材质不可用，直接拷贝源纹理到目标纹理
            Graphics.Blit(src, dest);
        }
    }
}