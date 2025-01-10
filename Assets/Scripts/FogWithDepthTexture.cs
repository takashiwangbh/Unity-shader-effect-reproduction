/*
这个脚本实现了基于深度纹理的雾效处理。
通过结合摄像机的深度信息和视锥体角点计算，可以在屏幕后处理中渲染出逼真的体积雾效果。
用户可以通过调节参数自定义雾的颜色、密度以及起始和结束范围。

*/

using UnityEngine;
using System.Collections;

public class FogWithDepthTexture : PostEffectsBase {

    // 雾效的 Shader
    public Shader fogShader;
    private Material fogMaterial = null;

    // 延迟加载材质，确保 Shader 检查通过后创建材质
    public Material material {  
        get {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
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

    // 当前摄像机的变换组件
    private Transform myCameraTransform;
    public Transform cameraTransform {
        get {
            if (myCameraTransform == null) {
                myCameraTransform = camera.transform;
            }
            return myCameraTransform;
        }
    }

    // 雾的密度
    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;

    // 雾的颜色
    public Color fogColor = Color.white;

    // 雾的起始和结束距离
    public float fogStart = 0.0f;
    public float fogEnd = 2.0f;

    // 启用时启用深度纹理
    void OnEnable() {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }
    
    // 每帧渲染时的处理
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            // 计算视锥体角点
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float fov = camera.fieldOfView; // 垂直视场角
            float near = camera.nearClipPlane; // 近裁剪面距离
            float aspect = camera.aspect; // 宽高比

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad); // 半高
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;   // 水平方向向量
            Vector3 toTop = cameraTransform.up * halfHeight;                // 垂直方向向量

            // 计算四个角点的方向向量
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            // 设置视锥体矩阵的四个角点
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            // 将视锥体矩阵传递给 Shader
            material.SetMatrix("_FrustumCornersRay", frustumCorners);

            // 设置雾的参数
            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);

            // 使用材质处理源纹理并渲染到目标纹理
            Graphics.Blit(src, dest, material);
        } else {
            // 如果材质不可用，直接拷贝源纹理到目标纹理
            Graphics.Blit(src, dest);
        }
    }
}
