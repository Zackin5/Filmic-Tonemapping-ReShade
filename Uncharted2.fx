// Reshade port of Uncharted 2 tonemap
// Base code sourced from John Hable's blog at http://filmicworlds.com/blog/filmic-tonemapping-operators/
// by Jace Regenbrecht

uniform bool U2_Lum <
	ui_label = "Use luminance";
	ui_tooltip = "Calculate tone based off each pixel's luminance value vs the RGB value.";
> = false;

uniform float U2_A <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Shoulder strength";
> = 0.22;

uniform float U2_B <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Linear strength";
> = 0.30;

uniform float U2_C <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Linear angle";
> = 0.10;

uniform float U2_D <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Toe strength";
> = 0.20;

uniform float U2_E <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Toe numerator";
> = 0.01;

uniform float U2_F <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Toe denominator";
> = 0.22;

uniform float U2_W <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 20.00;
	ui_label = "Linear White Point Value";
> = 11.2;

uniform float U2_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float U2_Gamma <
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

float3 Uncharted2Tonemap(float3 x)
{
	return ((x*(U2_A*x+U2_C*U2_B)+U2_D*U2_E)/(x*(U2_A*x+U2_B)+U2_D*U2_F))-U2_E/U2_F;
}

float3 Uncharted_Tonemap_Main(float4 pos : SV_Position, float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( U2_Gamma > 1.00 )
		texColor = pow(texColor,U2_Gamma);
		
	texColor *= U2_Exp;  // Exposure Adjustment

	float ExposureBias = 2.0f;
	float3 curr;
	
	// Do tonemapping on RGB or Luminance
	if(!U2_Lum)
		curr = Uncharted2Tonemap(ExposureBias*texColor);
	else
	{
		float lum = 0.2126f * texColor[0] + 0.7152 * texColor[1] + 0.0722 * texColor[2];
		float3 newLum = Uncharted2Tonemap(ExposureBias*lum);
		float lumScale = newLum / lum;
		curr = texColor*lumScale;
	}

	float3 whiteScale = 1.0f/Uncharted2Tonemap(U2_W);
	float3 color = curr*whiteScale;
    
	// Do the post-tonemapping gamma correction
	if( U2_Gamma > 1.00 )
		color = pow(color,1/U2_Gamma);
	
	return color;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique Uncharted2
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Uncharted_Tonemap_Main;
	}
}