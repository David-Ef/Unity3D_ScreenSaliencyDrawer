Shader "GaussianFilter"
{
    Properties
    {
        _MainTex ("Texture to filter", 2D) = "black" {}
        _Sigma ("Gaussian sigma parameter", float) = .1
    }
	
    CGINCLUDE

     // https://eri-st.eu/portfolio/projects/GazeTransViewer/
    // Helped removed the GPU artifacts:
    //		https://github.com/keijiro/GaussianBlur/blob/master/Assets/FilterTest.cs
        
    #include "UnityCG.cginc"
    
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    int _FilterOrientation;
    float _Sigma;

	#define KERNEL_SIZE 301

    float gauss(float v, float s){
        float m = ( v * v ) / (2. * ( s*s ) );
        return exp(-m);
    }

    float4 gauss_filter (v2f_img data, int orient) : SV_Target
    {
        _FilterOrientation = clamp(orient, 0, 1);
        
        float sw = 1.0/_ScreenParams.x;
        float sh = 1.0/_ScreenParams.y;

		float sum = 0.;
		float sumK = 0.;

		for( int i=0; i < KERNEL_SIZE; i++)
		{
			float tof = i - (KERNEL_SIZE-1) /2.;
			float2 offset = float2(tof, tof);

			offset *= float2(sw, sh);
			offset *= float2(1.-_FilterOrientation, _FilterOrientation);

			const float kernel = gauss(
					// X or Y is 0, so we sum to obtain the extent
					offset.x+offset.y,
					// Correction makes the filter isotropic
					_Sigma * max(1.,  sh/sw * _FilterOrientation ) );

			const float tmp = tex2D(_MainTex, data.uv + offset).a;
			sum += tmp * kernel;
			sumK += kernel;
		}

        return sum / sumK;
    }

    float4 frag_v (v2f_img data) : SV_Target
    {
	    return gauss_filter(data, 0);
    }

    float4 frag_h (v2f_img data) : SV_Target
    {
	    return gauss_filter(data, 1);
    }
    
    ENDCG
    
    SubShader
    {    	
        Pass
		{
	        ZTest Always Cull Off ZWrite Off
	        CGPROGRAM
	        #pragma vertex vert_img
	        #pragma fragment frag_v
	        ENDCG
        }
        Pass
		{
	        ZTest Always Cull Off ZWrite Off
	        CGPROGRAM
	        #pragma vertex vert_img
	        #pragma fragment frag_h
	        ENDCG
        }
    }
}
