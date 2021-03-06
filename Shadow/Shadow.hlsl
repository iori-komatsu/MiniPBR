#include <Shader/PostEffectCommon.fxsub>
#include <Shader/Parameter/Viewport.fxsub>
#include <Shader/ShadowMap/Constants.fxsub>

shared texture2D ShadowMap1 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap1";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap1.fx";
>;
shared texture2D ShadowMap2 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap2";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap2.fx";
>;
shared texture2D ShadowMap3 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap3";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap3.fx";
>;
shared texture2D ShadowMap4 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap4";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap4.fx";
>;
#if N_SHADOW_MAPS > 4
shared texture2D ShadowMap5 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap5";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap5.fx";
>;
shared texture2D ShadowMap6 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap6";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap6.fx";
>;
shared texture2D ShadowMap7 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap7";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap7.fx";
>;
shared texture2D ShadowMap8 : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR ShadowMap8";
    string Format = "R32F";
    int2   Dimensions = {ShadowMapSize, ShadowMapSize};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = ShadowMap8.fx";
>;
#endif
sampler2D Shadow1Samp = sampler_state {
    texture   = <ShadowMap1>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow2Samp = sampler_state {
    texture   = <ShadowMap2>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow3Samp = sampler_state {
    texture   = <ShadowMap3>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow4Samp = sampler_state {
    texture   = <ShadowMap4>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
#if N_SHADOW_MAPS > 4
sampler2D Shadow5Samp = sampler_state {
    texture   = <ShadowMap5>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow6Samp = sampler_state {
    texture   = <ShadowMap6>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow7Samp = sampler_state {
    texture   = <ShadowMap7>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
sampler2D Shadow8Samp = sampler_state {
    texture   = <ShadowMap8>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};
#endif

//-------------------------------------------------------------------------------------------------

void VS(
    in float4 pos : POSITION,
    in float4 coord : TEXCOORD0,
    out float4 oPos : POSITION,
    out float2 oCoord : TEXCOORD0
) {
    oPos = pos;
    oCoord = ViewportCoordToTexelCoord(coord.xy);
}

float4 PS(in float2 coord: TEXCOORD0) : COLOR {
    return tex2D(ScnSamp, coord);
}

//-------------------------------------------------------------------------------------------------

// ?????_?????O?^?[?Q?b?g???N???A?l
float4 ClearColor = {1, 1, 1, 0};
float ClearDepth  = 1.0;

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
