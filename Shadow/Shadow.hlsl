float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

//-------------------------------------------------------------------------------------------------

texture DepthBuffer : RENDERDEPTHSTENCILTARGET<
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "D24S8";
>;
texture2D ScnMap : RENDERCOLORTARGET<
    float2 ViewportRatio = {1.0, 1.0};
    string Format = "A16B16G16R16F";
>;
sampler2D ScnSamp = sampler_state {
    texture   = <ScnMap>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

#define SHADOW_MAP_SIZE 2048

shared texture2D ShadowMap : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap";
    string Format = "R16F";
    int2   Dimensions = {SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap.fx";
>;
sampler2D ShadowSamp = sampler_state {
    texture   = <ShadowMap>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

//-------------------------------------------------------------------------------------------------

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

// レンダリングターゲットのクリア値
float4 ClearColor = {1, 1, 1, 0};
float ClearDepth  = 1.0;

void VS(
    in float4 pos : POSITION,
    in float4 coord : TEXCOORD0,
    out float4 oPos : POSITION,
    out float2 oCoord : TEXCOORD0
){
    oPos = pos;
    oCoord = coord.xy + ViewportOffset;
}

float4 DrawShadowMap(float2 coord) {
    float d = tex2D(ShadowSamp, coord).r;
    if (d == 0.0) {
        return float4(0.2, 0.2, 0.5, 1);
    }
    d = exp(-d);
    return float4(d, d, d, 1.0);
}

float4 PS(in float2 coord: TEXCOORD0) : COLOR
{
    //return DrawShadowMap(coord);
    return tex2D(ScnSamp, coord);
}

////////////////////////////////////////////////////////////////////////////////////////////////

technique PostEffect <
    string Script = 
        "RenderColorTarget0=ScnMap;"
	    "RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
	    "ScriptExternal=Color;"
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    "Pass=PostEffect;"
    ;
> {
    pass PostEffect < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////
