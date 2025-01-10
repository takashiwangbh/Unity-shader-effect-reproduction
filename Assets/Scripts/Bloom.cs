/*
这个脚本实现了屏幕后处理的 Bloom（泛光）效果。
通过提取图像中高亮部分并对其进行模糊处理，再叠加到原图像上，
可以生成柔和的高光效果，增强画面的视觉表现力。
*/

using UnityEngine;
using System.Collections;

public class Bloom : PostEffectsBase {

    // 泛光效果的 Shader
    public Shader bloomShader;
    private Material bloomMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
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

    // 亮度阈值，高于此值的像素会参与泛光效果
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    // 屏幕后处理方法
    void OnRenderImage (RenderTexture src, RenderTexture dest) {
        if (material != null) {
            // 设置亮度阈值
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            // 计算降采样后的纹理宽高
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            
            // 创建初始的降采样纹理
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            
            // 提取高亮区域
            Graphics.Blit(src, buffer0, material, 0);
            
            // 迭代模糊处理
            for (int i = 0; i < iterations; i++) {
                // 设置当前模糊范围
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                
                // 创建临时缓冲区
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                // 垂直模糊
                Graphics.Blit(buffer0, buffer1, material, 1);
                
                // 释放旧的缓冲区并交换
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                
                // 水平模糊
                Graphics.Blit(buffer0, buffer1, material, 2);
                
                // 释放旧的缓冲区并交换
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            // 将模糊结果传递给 Shader，用于叠加到原图像上
            material.SetTexture("_Bloom", buffer0);  
            Graphics.Blit(src, dest, material, 3);  

            // 释放临时缓冲区
            RenderTexture.ReleaseTemporary(buffer0);
        } else {
            // 如果材质不可用，直接复制原始纹理
            Graphics.Blit(src, dest);
        }
    }
}
