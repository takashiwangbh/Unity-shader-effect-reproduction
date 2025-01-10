/*
脚本名称: BurnHelper (溶解效果辅助器)
用途: 此脚本用于动态控制材质的溶解效果。通过修改 `_BurnAmount` 属性，实现物体从完整到逐渐溶解的动画。
*/

using UnityEngine;
using System.Collections;

public class BurnHelper : MonoBehaviour {

    // 需要应用溶解效果的材质
    public Material material;

    // 控制溶解速度，范围 [0.01, 1.0]
    [Range(0.01f, 1.0f)]
    public float burnSpeed = 0.3f;

    // 当前溶解程度，范围 [0.0, 1.0]
    private float burnAmount = 0.0f;

    // 初始化逻辑
    void Start () {
        // 如果没有手动指定材质，尝试从当前物体或其子物体的 Renderer 中获取材质
        if (material == null) {
            Renderer renderer = gameObject.GetComponentInChildren<Renderer>();
            if (renderer != null) {
                material = renderer.material; // 获取 Renderer 的材质
            }
        }

        // 如果未能获取材质，则禁用该脚本
        if (material == null) {
            this.enabled = false; // 禁用脚本，防止报错
        } else {
            material.SetFloat("_BurnAmount", 0.0f); // 初始化溶解程度为 0
        }
    }
    
    // 每帧更新逻辑
    void Update () {
        // 使用 Time.time 和 burnSpeed 动态计算当前的溶解程度
        burnAmount = Mathf.Repeat(Time.time * burnSpeed, 1.0f);
        // 更新材质的 _BurnAmount 属性
        material.SetFloat("_BurnAmount", burnAmount);
    }
}