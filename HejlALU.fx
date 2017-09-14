// Reshade port of Hejl's ALU tonemap
// Base code sourced from Hable's GDC presentation at http://www.gdcvault.com/play/1012351/Uncharted-2-HDR slide #140
// by Jace Regenbrecht

uniform float HALU_W <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 20.00;
	ui_label = "Linear White Point Value";
> = 11.2;

uniform float HALU_Exp <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 20.00;
	ui_label = "Exposure";
> = 1.0;

uniform float HALU_Gamma <
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

float3 Hejl_ALU_Tonemap(float4 pos : SV_Position, float2 texcoord : TexCoord ) : COLOR
{
	float3 texColor = tex2D(ReShade::BackBuffer, texcoord ).rgb;
	
	// Do inital de-gamma of the game image to ensure we're operating in the correct colour range.
	if( HALU_Gamma > 1.00 )
		texColor = pow(texColor,HALU_Gamma);
		
	texColor *= HALU_Exp;  // Exposure Adjustment

	// Hejl ALU tonemap
	texColor = max(0, texColor-0.004);
	texColor = (texColor*(6.2*texColor+0.5))/(texColor*(6.2*texColor+1.7)+0.06);
	
	return texColor;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique HejlALU
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Hejl_ALU_Tonemap;
	}
}