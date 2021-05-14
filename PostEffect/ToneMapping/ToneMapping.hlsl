#include <Shader/Common.fxsub>
#include <Shader/ColorSpace.fxsub>
#include <Shader/Parameter/Viewport.fxsub>

// 0: Linear
// 1: ACES
// 2: Color-ratio preserving ACES
#define TONE_MAPPING 0

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
    oCoord = PixelCoordToTexelCoord(coord.xy);
}

// 出典:
// Krzysztof Narkowicz. "ACES Filmic Tone Mapping Curve". 2016-01-06.
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
#define DEFINE_ACES(floatN) \
    inline floatN ACES(floatN x) { \
        return saturate((x*(2.51f*x+0.03f))/(x*(2.43f*x+0.59f)+0.14f)); \
    }
DEFINE_ACES(float)
DEFINE_ACES(float3)

#if TONE_MAPPING == 1
    inline float3 ToneMapping(float3 rgb) {
        return ACES(rgb);
    }
#elif TONE_MAPPING == 2
    inline float3 ToneMapping(float3 rgb) {
        float inL = Luminance(rgb);
        float outL = ACES(inL);
        return (outL / inL) * rgb;
    }
#else
    inline float3 ToneMapping(float3 rgb) {
        return rgb;
    }
#endif

float4 PS(in float2 coord: TEXCOORD0) : COLOR {
    float4 inColor = tex2D(ScnSamp, coord);
    float3 outColor = ToneMapping(inColor.rgb);
    outColor = linear2srgb(outColor);
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
