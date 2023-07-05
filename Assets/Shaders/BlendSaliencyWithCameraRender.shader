Shader "BlendSaliencyWithCameraRender"
{
    Properties
    {
        _MainTex ("Camera texture", 2D) = "white" {}
        _SalTex ("Saliency texture", 2D) = "black" {}
        
        _salMax ("Max saliency value", float) = 0
        _BlendRatio ("Blend ratio", float) = .3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // https://eri-st.eu/portfolio/projects/GazeTransViewer/
			// Colormap, data from matplotlib docs
			static float3 coolwarm[33] = {
				float3(0.2298057, 0.298717966, 0.753683153),
				float3(0.26623388, 0.353094838, 0.801466763),
				float3(0.30386891, 0.406535296, 0.84495867),
				float3(0.342804478, 0.458757618, 0.883725899),
				float3(0.38301334, 0.50941904, 0.917387822),
				float3(0.424369608, 0.558148092, 0.945619588),
				float3(0.46666708, 0.604562568, 0.968154911),
				float3(0.509635204, 0.648280772, 0.98478814),
				float3(0.552953156, 0.688929332, 0.995375608),
				float3(0.596262162, 0.726149107, 0.999836203),
				float3(0.639176211, 0.759599947, 0.998151185),
				float3(0.681291281, 0.788964712, 0.990363227),
				float3(0.722193294, 0.813952739, 0.976574709),
				float3(0.761464949, 0.834302879, 0.956945269),
				float3(0.798691636, 0.849786142, 0.931688648),
				float3(0.833466556, 0.860207984, 0.901068838),
				float3(0.865395197, 0.86541021, 0.865395561),
				float3(0.897787179, 0.848937047, 0.820880546),
				float3(0.924127593, 0.827384882, 0.774508472),
				float3(0.944468518, 0.800927443, 0.726736146),
				float3(0.958852946, 0.769767752, 0.678007945),
				float3(0.96732803, 0.734132809, 0.628751763),
				float3(0.969954137, 0.694266682, 0.579375448),
				float3(0.966811177, 0.650421156, 0.530263762),
				float3(0.958003065, 0.602842431, 0.481775914),
				float3(0.943660866, 0.551750968, 0.434243684),
				float3(0.923944917, 0.49730856, 0.387970225),
				float3(0.89904617, 0.439559467, 0.343229596),
				float3(0.869186849, 0.378313092, 0.300267182),
				float3(0.834620542, 0.312874446, 0.259301199),
				float3(0.795631745, 0.24128379, 0.220525627),
				float3(0.752534934, 0.157246067, 0.184115123),
				float3(0.705673158, 0.01555616, 0.150232812)
			};

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            sampler2D _MainTex;
            sampler2D _SalTex;
            
            float _salMax;
            float _BlendRatio;

            fixed4 frag (v2f i) : SV_Target
            {                
                const float sal = tex2D(_SalTex, i.uv).r / _salMax;
            	
                // return fixed4(sal, sal, sal, 1);

                if (sal < 2.5e-1 || _salMax == 0)
                {
	                return tex2D(_MainTex, i.uv);
                }
            	
				//	Grayscale to coloured saliency map
				//		Get interp points in coolwarm array
				float interp_val = sal * 32.;
				const int2 interp = int2( floor(interp_val), ceil(interp_val) );

				//		Interpolate between the two values
				interp_val = frac(interp_val);
				const float3 sal_cmap = coolwarm[interp.x] * (1.-interp_val) + coolwarm[interp.y] * interp_val;
                
                fixed4 col = tex2D(_MainTex, i.uv) * _BlendRatio +
                	float4(sal_cmap, 1) * (1.f-_BlendRatio);
                return col;
            }
            
            ENDCG
        }
    }
}
