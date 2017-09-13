// Reshade port of luminance ACES curve by Krzysztof Narkowicz.
// Base code sourced from Krzysztof Narkowicz's blog at https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
// by Jace Regenbrecht

uniform float ACESN_A <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
	ui_label = "A value";
> = 2.51;

uniform float ACESN_B <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "B value";
> = 0.03;

uniform float ACESN_C <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
	ui_label = "C value";
> = 2.43;

uniform float ACESN_D <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "D value";
> = 0.59;

uniform float ACESN_E <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "E value";
> = 0.14;

uniform float ACESN_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float ACESN_Gamma <
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

float3 aces_main_nark(float4 pos : SV_Position, float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( ACESN_Gamma > 1.00 )
		texColor = pow(texColor,ACESN_Gamma);
		
	texColor *= ACESN_Exp;  // Exposure Adjustment

	// ACES
	texColor = saturate((texColor*(ACESN_A*texColor+ACESN_B))/(texColor*(ACESN_C*texColor+ACESN_D)+ACESN_E));
    
	// Do the post-tonemapping gamma correction
	if( ACESN_Gamma > 1.00 )
		texColor = pow(texColor,1/ACESN_Gamma);
	
	return texColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique ACESNarkowicz
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = aces_main_nark;
	}
}