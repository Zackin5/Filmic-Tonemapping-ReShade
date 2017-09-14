// Reshade port of Hejl's 2015 filmic tonemap
// Base code sourced from a Jim Hejl tweet at https://twitter.com/jimhejl/status/633777619998130176
// by Jace Regenbrecht

uniform float H2015_W <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 20.00;
	ui_label = "Linear White Point Value";
> = 11.2;

uniform float H2015_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float H2015_Gamma <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 3.00;
	ui_label = "Gamma value";
	ui_tooltip = "Most monitors/images use a value of 2.2. Setting this to 1 disables the pre-tonemapping degamma of the game image, causing that ugly washed out effect you see in the SweetFx implementation.";
> = 2.2;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 Hejl2015_Tonemap(float4 pos : SV_Position, float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( H2015_Gamma > 1.00 )
		texColor = pow(texColor,H2015_Gamma);
		
	texColor *= H2015_Exp;  // Exposure Adjustment

	// Hejl tonemap
	float4 vh = float4(texColor, H2015_W);	// pack: [r,g,b,w]
	float4 va = (1.425f * vh) + 0.05f;		// eval filmic curve
	float4 vf = ((vh * va + 0.004f) / ((vh * (va + 0.55f) + 0.0491f))) - 0.0821f;
	texColor = vf.rgb / vf.www;				// White point correction
    
	// Do the post-tonemapping gamma correction
	if( H2015_Gamma > 1.00 )
		texColor = pow(texColor,1/H2015_Gamma);
	
	return texColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique UNCHARTED2
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Uncharted_Tonemap_Main;
	}
}