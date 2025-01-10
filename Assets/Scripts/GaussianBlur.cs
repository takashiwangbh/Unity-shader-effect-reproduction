/*
这个脚本实现了屏幕后处理的高斯模糊效果。
通过多次迭代模糊图像，可以实现不同强度的模糊效果。
同时支持自定义模糊范围和降采样率，以提高性能和控制模糊的精细程度。

*/

using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase {

    // 高斯模糊的 Shader
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }  
    }

    // 模糊迭代次数，值越大模糊越强
    [Range(0, 4)]
    public int iterations = 3;
    
    // 每次迭代的模糊范围，值越大模糊越强
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    
    // 降采样率，值越大性能越高，但模糊精度会降低
    [Range(1, 8)]
    public int downSample = 2;

    // 第三版实现：通过多次迭代实现更大的模糊效果
    void OnRenderImage (RenderTexture src, RenderTexture dest) {
        if (material != null) {
            // 计算降采样后的纹理宽高
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;

            // 创建初始的降采样纹理
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            // 首先将原始图像拷贝到降采样纹理
            Graphics.Blit(src, buffer0);

            // 进行迭代模糊处理
            for (int i = 0; i < iterations; i++) {
                // 设置当前模糊范围
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                // 创建临时缓冲区
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 垂直模糊
                Graphics.Blit(buffer0, buffer1, material, 0);

                // 释放旧的缓冲区并交换
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 水平模糊
                Graphics.Blit(buffer0, buffer1, material, 1);

                // 释放旧的缓冲区并交换
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            // 将最终模糊结果拷贝到目标纹理
            Graphics.Blit(buffer0, dest);
            RenderTexture.ReleaseTemporary(buffer0);
        } else {
            // 如果材质不可用，直接复制原始纹理
            Graphics.Blit(src, dest);
        }
    }
}
