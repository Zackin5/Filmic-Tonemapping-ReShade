// Reshade port of optimized Haarm-Pieter Duiker curve by Jim Hejl and Richard Burgess-Dawson.
// Base code sourced from John Hable's blog at http://filmicworlds.com/blog/filmic-tonemapping-operators/
// by Jace Regenbrecht

uniform float HPD_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float HPD_Gamma <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 3.00;
	ui_label = "Gamma value";
	ui_tooltip = "Most monitors/images use a value of 2.2. Setting this to 1 disables the pre-tonemapping degamma of the game image, causing a washed out effect.";
> = 2.2;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 hpd_main_opt( float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( HPD_Gamma > 1.00 )
		texColor = pow(texColor,HPD_Gamma);
		
	texColor *= HPD_Exp;  // Exposure Adjustment

	// HPD
	float3 x = max(0,texColor-0.004);
	float3 retColor = (x*(6.2*x+.5))/(x*(6.2*x+1.7)+0.06);
	
	return retColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique HaarmPieterDuikerSimple
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = hpd_main_opt;
	}
}