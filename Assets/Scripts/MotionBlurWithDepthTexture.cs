/*
这个脚本实现了基于深度纹理的运动模糊效果。
通过记录上一帧的视图投影矩阵，并结合当前帧的深度信息，
模拟物体运动时的模糊效果，增强画面动态表现力。
*/

using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : PostEffectsBase {

    // 运动模糊的 Shader
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }  
    }

    // 当前摄像机
    private Camera myCamera;
    public Camera camera {
        get {
            if (myCamera == null) {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    // 模糊强度参数
    [Range(0.0f, 1.0f)]
    public float blurSize = 0.5f;

    // 上一帧的视图投影矩阵
    private Matrix4x4 previousViewProjectionMatrix;
    
    // 在启用时初始化深度纹理模式和矩阵
    void OnEnable() {
        // 启用摄像机的深度纹理模式
        camera.depthTextureMode |= DepthTextureMode.Depth;

        // 初始化上一帧的视图投影矩阵
        previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
    }
    
    // 在屏后处理阶段渲染运动模糊效果
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            // 设置模糊强度参数
            material.SetFloat("_BlurSize", blurSize);

            // 设置上一帧的视图投影矩阵
            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);

            // 计算当前帧的视图投影矩阵和其逆矩阵
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;

            // 将矩阵传递给 Shader
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);

            // 更新上一帧的视图投影矩阵为当前帧
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            // 使用材质处理源纹理并渲染到目标纹理
            Graphics.Blit(src, dest, material);
        } else {
            // 如果材质不可用，直接拷贝源纹理到目标纹理
            Graphics.Blit(src, dest);
        }
    }
}
