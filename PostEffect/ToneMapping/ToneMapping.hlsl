#include <Shader/Common.fxsub>
#include <Shader/ColorSpace.fxsub>
#include <Shader/Parameter/Viewport.fxsub>

// 0: Linear
// 1: ACES
#define TONE_MAPPING 1

// パラメータ操作用オブジェクト
float  Si   : CONTROLOBJECT < string name = "(self)"; string item = "Si";   >; // スケール

// 露光 (アクセサリの Si はUIで指定された値の10倍が取得されるので、0.1倍してもとに戻す)
static float Exposure = Si * 0.1;

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

//-------------------------------------------------------------------------------------------------

// 出典:
// Stephen Hill. BakingLab/ACES.hlsl.
// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
// (MIT License)

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
static const float3x3 ACESInputMat = {
    {0.59719, 0.35458, 0.04823},
    {0.07600, 0.90834, 0.01566},
    {0.02840, 0.13383, 0.83777}
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat = {
    { 1.60475, -0.53108, -0.07367},
    {-0.10208,  1.10813, -0.00605},
    {-0.00327, -0.07276,  1.07602}
};

float3 RRTAndODT(float3 v) {
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 ACES(float3 color) {
    return saturate(
        mul(ACESOutputMat,
            RRTAndODT(
                mul(ACESInputMat, color)
            )
        )
    );
}

//-------------------------------------------------------------------------------------------------

float4 PS(in float2 coord: TEXCOORD0) : COLOR {
    float4 inColor = tex2D(ScnSamp, coord);
#if TONE_MAPPING == 1
    float3 outColor = ACES(inColor.rgb * Exposure) * 1.8;
#else
    float3 outColor = saturate(inColor.rgb * Exposure);
#endif
    outColor = Linear2sRGB(outColor);
    return float4(outColor, inColor.a);
}

////////////////////////////////////////////////////////////////////////////////////////////////

// レンダリングターゲットのクリア値
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

////////////////////////////////////////////////////////////////////////////////////////////////
