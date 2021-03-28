Shader "SolarSystem/Earth" {

	Properties {
		_MainTex("Albedo", 2D) = "black" {}
		_NightTex("Night Texture", 2D) = "black" {}
		_CloudTex("Cloud Texture", 2D) = "black" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_SpecularMap("Specular Map", 2D) = "black" {}
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Glossiness("Glossiness", Float) = 1.0
		_SurfaceShininess("Surface Shininess", Float) = 1.0
		_SurfaceFalloff("Surface Falloff", Float) = 1.0
		_AtmoColor("Atmosphere Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_AtmoShininess("Atmosphere Shininess", Float) = 1.0
		_AtmoFalloff("Atmosphere Falloff", Float) = 1.0
		_AtmoSize("Atmosphere Height", Float) = 1.0
		_CloudSize("Cloud Height", Float) = 1.0
		_Speed("Cloud Speed", Float) = 1
	}
	
	SubShader {
		Tags { "Queue" = "Geometry" "RenderType" = "Transparent" }
		/*
		Pass{
			Tags{ "LightMode" = "ForwardBase" }
			Name "BASE"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			struct vertexInput {
				float4 vertex : POSITION;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
			};
			vertexOutput vert(vertexInput v) {
				vertexOutput o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			float4 frag(vertexOutput i) : Color{
				return float4(0, 0, 0, 1);
			}
			ENDCG
		}*/

		Pass {
			Tags { "LightMode" = "ForwardAdd" }
			Name "BODY"
			Blend One Zero

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
			
			uniform sampler2D _MainTex;
			uniform sampler2D _NightTex;
			uniform sampler2D _CloudTex;
			uniform sampler2D _BumpMap;
			uniform sampler2D _SpecularMap;
			uniform float4 _Color;
			uniform float4 _AtmoColor;
			uniform float _Glossiness;
        	uniform float _SurfaceFalloff;
        	uniform float _SurfaceShininess;
			uniform float _Speed;
			
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 tangent : TEXCOORD2;
				float3 binormal : TEXCOORD3;
				float3 view : TEXCOORD4;
				float3 light : TEXCOORD5;
			};
			
			vertexOutput vert(vertexInput v) {
				vertexOutput o;
				
				float3 normalDir = normalize (mul (unity_ObjectToWorld, float4 (v.normal,0)).xyz);
				float3 viewDir = normalize (_WorldSpaceCameraPos.xyz - mul (unity_ObjectToWorld, v.vertex));
				float3 lightDir = normalize (mul (unity_ObjectToWorld, v.vertex) - _WorldSpaceLightPos0.xyz);
				
				float atmo;
				float light = saturate (dot (normalDir, -lightDir) + .2);
            	atmo = saturate (pow (1.0 - dot (viewDir, normalDir) + .2, _SurfaceFalloff) * _SurfaceShininess);
            	
            	o.pos = UnityObjectToClipPos (v.vertex);
				o.tex = v.texcoord;
				o.tex.zw = float2 (light, atmo);
				
				o.normal = normalDir;
				o.tangent = normalize (mul (float4 (v.tangent.xyz, 0), unity_WorldToObject).xyz);
				o.binormal = normalize (cross (o.normal, o.tangent) * v.tangent.w);
				o.view = viewDir;
				o.light = lightDir;
				
				return o;
			}
			
			float4 frag(vertexOutput i) : Color {
				float4 normalTex = tex2D (_BumpMap, i.tex.xy);
				float3 localCoords = float3 (2.0 * normalTex.ag - float2 (1.0, 1.0), 1.0);
				float3x3 local2WorldTranspose = float3x3(i.tangent, i.binormal, i.normal);
				float3 normalDir = normalize (mul (localCoords, local2WorldTranspose));
				float normalLight = saturate (dot (-i.light, normalDir) + .1);
				
				float4 tex = saturate(tex2D (_MainTex, i.tex.xy) + pow (dot (reflect (i.light, normalDir), i.view) * tex2D (_SpecularMap, i.tex.xy) * _Glossiness, 2));
				//float cloud = tex2D(_CloudTex, i.tex.xy + float2(-0.15,0) * _Time.y * _Speed).a * .5;
				//tex = lerp(tex, float4(0, 0, 0, 0), cloud);	// approximate cloud shadow
				
				float4 nightTex = tex2D (_NightTex, i.tex.xy);
				float light = saturate (i.tex.z * 2);
				
				return lerp (nightTex, lerp (tex * normalLight, _Color, i.tex.w) * i.tex.z, light);
			}
			
			ENDCG
		}
			
		Pass{
			Tags{ "LightMode" = "ForwardAdd" }
			Name "CLOUD"
			Blend One OneMinusSrcAlpha
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd

			uniform sampler2D _CloudTex;
			uniform float4 _Color;
			uniform float4 _AtmoColor;
			uniform float4 _Light;
			uniform float _AtmoFalloff;
			uniform float _AtmoShininess;
			uniform float _CloudSize;
			uniform float _Speed;

			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 col : COLOR;
				float3 vertex : TEXCOORD0;
				float4 tex : TEXCOORD1;
			};

			vertexOutput vert(vertexInput v) {
				vertexOutput o;

				v.vertex.xyz *= _CloudSize;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.vertex = mul(unity_ObjectToWorld, v.vertex);

				float3 normalDir = normalize(mul(unity_ObjectToWorld, float4 (v.normal, 0)).xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul (unity_ObjectToWorld, v.vertex));
				float3 lightDir = normalize(mul(unity_ObjectToWorld, v.vertex) - _WorldSpaceLightPos0.xyz);
				float light = saturate(min(dot(normalDir, -lightDir), dot(normalDir, viewDir) * 5));
				o.col = float4(light, light, light, 1);
				o.tex = v.texcoord;
				o.tex.z = _Time.y * _Speed;

				return o;
			}

			float4 frag(vertexOutput i) : Color{
				// cloud animation
				float t =  i.tex.z;
				float4 c1 = tex2D(_CloudTex, i.tex.xy + float2(-0.15,0) * t);
				float4 c2 = tex2D(_CloudTex, -i.tex.xy + float2(0.32,0) * t);
				float a3 = tex2D(_CloudTex, i.tex.xy + float2(-0.45,0) * t).a ;
				float a4 = tex2D(_CloudTex, -i.tex.xy + float2(0.60,0) * t).a ;
				return (c1 * a4 + c2 * a3) * i.col;
			}

			ENDCG
		}
		
		Pass {
			Tags { "LightMode" = "ForwardAdd" }
			Name "ATMOSPHERE"
			Cull Front
			Blend SrcAlpha One
			ZWrite Off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
			
			uniform float4 _Color;
			uniform float4 _AtmoColor;
			uniform float4 _Light;
        	uniform float _AtmoFalloff;
        	uniform float _AtmoShininess;
        	uniform float _AtmoSize;
			
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 col : COLOR;
				float3 vertex : TEXCOORD0;
			};
			
			vertexOutput vert(vertexInput v) {
				vertexOutput o;
				
				v.vertex.xyz *= _AtmoSize;
            	o.pos = UnityObjectToClipPos (v.vertex);
				o.vertex = mul (unity_ObjectToWorld, v.vertex);
				
				float3 normalDir = normalize (mul (unity_ObjectToWorld, float4 (v.normal,0)).xyz);
				float3 viewDir = -normalize (_WorldSpaceCameraPos.xyz - mul (unity_ObjectToWorld, v.vertex));
				float3 lightDir = normalize (mul (unity_ObjectToWorld, v.vertex) - _WorldSpaceLightPos0.xyz);
				float atmo;
				float light = saturate (dot (normalDir, -lightDir) + .5);
            	atmo = saturate (pow (dot (viewDir, normalDir), _AtmoFalloff) * _AtmoShininess);
				o.col = _AtmoColor * light * atmo;
				
				return o;
			}
			
			float4 frag(vertexOutput i) : Color {
				return i.col;
			}
			
			ENDCG
		}
	}
	
	Fallback "Diffuse"
}