// Reshade port of luminance ACES curve from The Baking Lab demo.
// Base code sourced from Matt Pettineo's work at https://github.com/TheRealMJP/BakingLab
// by Jace Regenbrecht

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

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
static const float3x3 ACESInputMat =
{
    {0.59719, 0.35458, 0.04823},
    {0.07600, 0.90834, 0.01566},
    {0.02840, 0.13383, 0.83777}
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat =
{
    { 1.60475, -0.53108, -0.07367},
    {-0.10208,  1.10813, -0.00605},
    {-0.00327, -0.07276,  1.07602}
};

float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 aces_main_bakinglab( float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( HPD_Gamma > 1.00 )
		texColor = pow(texColor,ACESN_Gamma);
		
	texColor *= ACESN_Exp;  // Exposure Adjustment

	// ACES
	float3 retColor = mul(ACESInputMat, texColor);
	
	retColor = RRTAndODTFit(texColor);
	
	retColor = mul(ACESOutputMat, texColor);
	
	retColor = saturate(retColor);
    
	// Do the post-tonemapping gamma correction
	if( U2_Gamma > 1.00 )
		retColor = pow(color,1/U2_Gamma);
	else
		retColor = pow(color,1/2.2);
	
	return retColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique ACESBakingLab
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = aces_main_bakinglab;
	}
}