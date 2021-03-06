// Reshade port of Reinhard tonemap
// Based on code from John Hable's and Tom Madams' blogs at http://filmicworlds.com/blog/filmic-tonemapping-operators/ and https://imdoingitwrong.wordpress.com/2010/08/19/why-reinhard-desaturates-my-blacks-3/ respectively
// by Jace Regenbrecht

uniform bool R_Lum <
	ui_label = "Use luminance";
	ui_tooltip = "Calculate tone based off each pixel's luminance value vs the RGB value.";
> = false;

uniform bool R_Simple <
	ui_label = "Simple Equation";
	ui_tooltip = "Use the simplistic Reinhard equation (doesn't support white point but is moderately cheaper computationally).";
> = false;

uniform float R_W <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 20.00;
	ui_label = "Linear White Point Value";
> = 5.0;

uniform float R_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float R_Gamma <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 3.00;
	ui_label = "Gamma value";
	ui_tooltip = "Most monitors/images use a value of 2.2. Setting this to 1 disables the inital color space conversion from gamma to linear.";
> = 2.2;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 ReinhardSimple(float3 x)
{
	return x/(1+x);
}

float3 ReinhardComplex(float3 x, float white)
{
	return (x*(1+(x/pow(white, 2))))/(1+x);
}

float3 Reinhard_Tonemap_Main(float4 pos : SV_Position, float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( R_Gamma > 1.00 )
		texColor = pow(texColor,R_Gamma);
		
	texColor *= R_Exp;  // Exposure Adjustment
	
	float3 processColor;
	float lum;
	
	// Determine if we're operating on luminance or RGB
	if(R_Lum)
	{
		lum = 0.2126f * texColor[0] + 0.7152 * texColor[1] + 0.0722 * texColor[2];
		processColor = float3(lum, 0, 0);
	}
	else
		processColor = texColor;
	
	// Run the tonemapping equations
	if(R_Simple)
		processColor = ReinhardSimple(processColor);
	else
		processColor = ReinhardComplex(processColor, R_W);
	
	// Do luminance adjustments
	if(R_Lum)
	{
		float lumScale = processColor / lum;
		processColor = texColor * lumScale;
	}
    
	// Do the post-tonemapping gamma correction
	if( R_Gamma > 1.00 )
		texColor = pow(processColor,1/R_Gamma);
	else
		texColor = processColor;
	
	return texColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique Reinhard
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Reinhard_Tonemap_Main;
	}
}