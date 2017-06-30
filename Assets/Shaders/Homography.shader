Shader "Unlit/Homography"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Hba0 ("HBA0", Vector) = (1,0,0,0)
		_Hba1 ("HBA1", Vector) = (1,0,0,0)
		_Hba2 ("HBA2", Vector) = (1,0,0,0)
		_resA ("ResA", Vector) = (1,1,0,0)
		_resB ("ResB", Vector) = (1,1,0,0)
		_bgAmp ("Wave Amplitude", Vector) = (0.3 ,0.35, 0.25, 0.25)
		_bgFreq ("Wave Frequency", Vector) = (1.3, 1.35, 1.25, 1.25)
		_bgSteep ("Wave Steepness", Vector) = (1.0, 1.0, 1.0, 1.0)
		_bgSpeed ("Wave Speed", Vector) = (1.2, 1.375, 1.1, 1.5)
		_bgDirAB ("Wave Direction", Vector) = (0.3 ,0.85, 0.85, 0.25)
		_bgDirCD ("Wave Direction", Vector) = (0.1 ,0.9, 0.5, 0.5)

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uvH : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 uvMesh : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float3 _Hba0;
			float3 _Hba1;
			float3 _Hba2;
			float2 _resA;
			float2 _resB;

			half4 _bgSteep;
			half4 _bgAmp;
			half4 _bgFreq;
			half4 _bgSpeed;
			half4 _bgDirAB;
			half4 _bgDirCD;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvH = o.vertex;
				o.uvMesh = v.vertex.xy;
				return o;
			}

			half3 GerstnerOffset4 (half2 xzVtx, half4 steepness, half4 amp, half4 freq, half4 speed, half4 dirAB, half4 dirCD) 
			{
				half3 offsets;
				
				half4 AB = steepness.xxyy * amp.xxyy * dirAB.xyzw;
				half4 CD = steepness.zzww * amp.zzww * dirCD.xyzw;
				
				half4 dotABCD = freq.xyzw * half4(dot(dirAB.xy, xzVtx), dot(dirAB.zw, xzVtx), dot(dirCD.xy, xzVtx), dot(dirCD.zw, xzVtx));
				half4 TIME = _Time.yyyy * speed;
				
				half4 COS = cos (dotABCD + TIME);
				half4 SIN = sin (dotABCD + TIME);
				
				offsets.x = dot(COS, half4(AB.xz, CD.xz));
				offsets.z = dot(COS, half4(AB.yw, CD.yw));
				offsets.y = dot(SIN, amp);

				return offsets;			
			}	
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 screenPos = float3(i.uvH.xy, i.uvH.w) / i.uvH.w;
				//screenPos.y *= -1;
				screenPos.xy = screenPos.xy*0.5+0.5;

				screenPos.xy *= _resA;
				float3 newScreenPos = float3(dot(_Hba0, screenPos), dot(_Hba1, screenPos), dot(_Hba2, screenPos));
				newScreenPos /= newScreenPos.z;
				newScreenPos.xy /= _resB;
				float2 uv = newScreenPos.xy;

				//out of bounds term
				float oob = (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1) ? 0 : 1;
				oob = saturate(oob * min(min(abs(1.0-uv.x), abs(1.0-uv.y)), min(abs(uv.x), abs(uv.y)))/0.05);
				float2 gridPos = i.uvMesh * 30;
				float3 waterPos = GerstnerOffset4(gridPos, _bgSteep, _bgAmp, _bgFreq, _bgSpeed, _bgDirAB, _bgDirCD);
				float4 waterGrid = 1;
				waterGrid.rgb = lerp(0, float3(0.2,0.0,0.2), saturate((waterPos.y)*0.5+0.5));

				fixed4 col = lerp(waterGrid, tex2D(_MainTex, uv), oob);
				return col;
			}
			ENDCG
		}
	}
}
