Shader "Surface Shader2 with Vertex Shader" {
    Properties {
        _ColorTint ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BumpMap ("Normalmap", 2D) = "bump" {}
        _Amount ("Extrusion Amount", Range(-0.5, 0.5)) = 0.1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM

        // Adding vertex shader functions
        #pragma surface surf CustomLambert vertex:myvert finalcolor:mycolor addshadow exclude_path:deferred exclude_path:prepass nometa
        #pragma target 3.0

        fixed4 _ColorTint;
        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _Amount;

        struct Input {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        // Vertex shader: extrude vertices according to normal direction
        void myvert(inout appdata_full v) {
            v.vertex.xyz += v.normal * _Amount;
        }

        // Surface shaders: handle the appearance of materials
        void surf(Input IN, inout SurfaceOutput o) {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            o.Albedo = tex.rgb;
            o.Alpha = tex.a;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }

        // 自定义光照模型：模拟简单的 Lambert 漫反射光照
        half4 LightingCustomLambert(SurfaceOutput s, half3 lightDir, half atten) {
            half NdotL = dot(s.Normal, lightDir);
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
            c.a = s.Alpha;
            return c;
        }

        // 自定义最终颜色处理：应用颜色调整
        void mycolor(Input IN, SurfaceOutput o, inout fixed4 color) {
            color *= _ColorTint;
        }

        ENDCG
    }
    FallBack "Legacy Shaders/Diffuse"
}
