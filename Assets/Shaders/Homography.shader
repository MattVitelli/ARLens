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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float3 _Hba0;
			float3 _Hba1;
			float3 _Hba2;
			float2 _resA;
			float2 _resB;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvH = o.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 screenPos = float3(i.uvH.xy, i.uvH.w) / i.uvH.w;
				screenPos.y *= -1;
				//screenPos.xy = screenPos.xy*0.5+0.5;

				//screenPos.xy *= _resA;
				float3 newScreenPos = float3(dot(_Hba0, screenPos), dot(_Hba1, screenPos), dot(_Hba2, screenPos));
				newScreenPos /= newScreenPos.z;
				//newScreenPos.xy /= _resB;

				float2 uv = float2(newScreenPos.x, newScreenPos.y) * 0.5 + 0.5;
				// sample the texture
				fixed4 col = tex2D(_MainTex, uv);
				return col;
			}
			ENDCG
		}
	}
}
