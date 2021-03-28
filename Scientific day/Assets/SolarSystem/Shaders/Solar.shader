Shader "SolarSystem/Solar" {

	Properties {
		_MainTex("Albedo", 2D) = "black" {}
		_DistortTex("Distort Texture", 2D) = "bump" {}
		[HDR]_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_SurfaceShininess("Surface Shininess", Float) = 1.0
		_SurfaceFalloff("Surface Falloff", Float) = 1.0
		_Speed("Speed", Float) = 0.01
		_DistortIntensity("Distort Intensity", Range(0 , 0.05)) = 0.04
		_Length("Length", Float) = 0
		_Offset("Offset", Float) = 0
	}
	
	SubShader {
		Tags { "RenderType" = "Opaque" }
		Pass {
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#include "UnityStandardUtils.cginc"
			#pragma vertex vert
			#pragma fragment frag
			
			uniform sampler2D _MainTex;
			uniform sampler2D _DistortTex;
			uniform float4 _Color;
        	uniform float _SurfaceFalloff;
        	uniform float _SurfaceShininess;
			uniform float _Speed;
			uniform float _DistortIntensity;
			uniform float _Length;
			uniform float _Offset;
			
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
			};
			
			vertexOutput vert(vertexInput v) {
				vertexOutput o;
				
				float3 normalDir = normalize (mul (unity_ObjectToWorld, float4 (v.normal,0)).xyz);
				float3 viewDir = normalize (_WorldSpaceCameraPos.xyz - mul (unity_ObjectToWorld, v.vertex));
				
				float atmo;
            	atmo = saturate (pow (1.0 - dot (viewDir, normalDir), _SurfaceFalloff));
				atmo = saturate(atmo + ( -UnityObjectToViewPos( v.vertex.xyz ).z -_ProjectionParams.y - _Offset ) / _Length);
            	
            	o.pos = UnityObjectToClipPos (v.vertex);
				o.tex = v.texcoord;
				o.tex.w = atmo;
				
				return o;
			}
			
			float4 frag(vertexOutput i) : Color {

				float2 distortTex = UnpackScaleNormal( tex2D( _DistortTex, i.tex.xy), 1).xy * _DistortIntensity;

				float4 tex1 = tex2D (_MainTex, i.tex.xy + distortTex + float2(-0.15,0) * _Time.y * _Speed);
				float4 tex2 = tex2D (_MainTex, i.tex.xy + distortTex + float2(0.09,0.09) * _Time.y * _Speed);
				float4 tex = (tex1 + tex2) * 0.5;
				
				return lerp (tex, _Color, i.tex.w) * _SurfaceShininess;
			}
			
			ENDCG
		}
		
	}
	
	Fallback "Diffuse"
}