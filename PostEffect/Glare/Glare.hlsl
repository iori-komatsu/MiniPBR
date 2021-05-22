#include <Shader/PostEffectCommon.fxsub>
#include <Shader/Math.fxsub>
#include <Shader/Parameter/Viewport.fxsub>
#include <Shader/ColorSpace.fxsub>

// パラメータ操作用オブジェクト
float  XYZ : CONTROLOBJECT < string name = "(self)"; string item = "XYZ";   >;

static const float BloomThreshold = exp2(-0.01 * XYZ.x);
static const int   BlurRadius = 3;
static const float BlurStdDev = 2;

static const float BloomMapViewportRatio[5] = {
    1.0, 1.0, 0.5, 0.25, 0.125
};

//-------------------------------------------------------------------------------------------------

#define DEFINE_BLOOM_MAP(map_name, samp_name, ratio) \
    texture2D map_name : RENDERCOLORTARGET <   \
        float2 ViewportRatio = {ratio, ratio}; \
        int MipLevels = 1;                     \
        string Format = "A16B16G16R16F";       \
    >;                                         \
    sampler2D samp_name = sampler_state {      \
        texture = <map_name>;                  \
        MinFilter = LINEAR;                    \
        MagFilter = LINEAR;                    \
        MipFilter = NONE;                      \
        AddressU = BORDER;                     \
        AddressV = BORDER;                     \
        BorderColor = 0.0;                     \
    };

DEFINE_BLOOM_MAP(BloomMap0,  BloomSamp0,  BloomMapViewportRatio[0])
DEFINE_BLOOM_MAP(BloomMap1X, BloomSamp1X, BloomMapViewportRatio[1])
DEFINE_BLOOM_MAP(BloomMap1Y, BloomSamp1Y, BloomMapViewportRatio[1])
DEFINE_BLOOM_MAP(BloomMap2X, BloomSamp2X, BloomMapViewportRatio[2])
DEFINE_BLOOM_MAP(BloomMap2Y, BloomSamp2Y, BloomMapViewportRatio[2])
DEFINE_BLOOM_MAP(BloomMap3X, BloomSamp3X, BloomMapViewportRatio[3])
DEFINE_BLOOM_MAP(BloomMap3Y, BloomSamp3Y, BloomMapViewportRatio[3])
DEFINE_BLOOM_MAP(BloomMap4X, BloomSamp4X, BloomMapViewportRatio[4])
DEFINE_BLOOM_MAP(BloomMap4Y, BloomSamp4Y, BloomMapViewportRatio[4])

//-------------------------------------------------------------------------------------------------

void VS(
    in float4 pos : POSITION,
    in float4 coord : TEXCOORD0,
    out float4 oPos : POSITION,
    out float2 oCoord : TEXCOORD0,
    uniform in float2 viewportRatio // 入力テクスチャの ViewportRatio
) {
    oPos = pos;
    oCoord = ViewportCoordToTexelCoord(coord.xy, viewportRatio);
}

float4 ExtractBrightAreaPS(in float2 coord : TEXCOORD0) : COLOR {
    float4 inColor = tex2D(ScnSamp, coord);
    float inL = Luminance(inColor.rgb);
    float outL = max(0, inL - BloomThreshold);
    float3 outColor = (outL / inL) * inColor.rgb;
    return float4(outColor, inColor.a);
}

inline float Gaussian(float x, float variance) {
    return exp(-pow2(x) / (2 * variance));
}

float4 XBlurPS(
    in float2 coord : TEXCOORD0,
    uniform in sampler2D samp,     // 入力テクスチャのサンプラー
    uniform in float viewportRatio // 入力テクスチャの ViewportRatio
) : COLOR {
    const float variance = pow2(BlurStdDev);

    float texelSize = 1.0 / (ViewportSize.x * viewportRatio);

    float3 c = tex2D(samp, coord).rgb; // Gaussian(0, σ^2) == 1
    float z = 1;

    for (int x = 1; x <= BlurRadius; x++) {
        float w = Gaussian(x, variance);
        float offset = texelSize * (x + 0.5);
        c += w * tex2D(samp, coord + float2(offset, 0)).rgb;
        c += w * tex2D(samp, coord - float2(offset, 0)).rgb;
        z += 2*w;
    }

    return float4(c / z, 1.0);
}

float4 YBlurPS(
    in float2 coord : TEXCOORD0,
    uniform in sampler2D samp,     // 入力テクスチャのサンプラー
    uniform in float viewportRatio // 入力テクスチャの ViewportRatio
) : COLOR {
    const float variance = pow2(BlurStdDev);

    float texelSize = 1.0 / (ViewportSize.y * viewportRatio);

    float3 c = tex2D(samp, coord).rgb; // Gaussian(0, σ^2) == 1
    float z = 1;

    for (int y = 1; y <= BlurRadius; y++) {
        float w = Gaussian(y, variance);
        float offset = texelSize * (y + 0.5);
        c += w * tex2D(samp, coord + float2(0, offset)).rgb;
        c += w * tex2D(samp, coord - float2(0, offset)).rgb;
        z += 2*w;
    }

    return float4(c / z, 1.0);
}

float4 SumPS(
    in float2 coord : TEXCOORD0
) : COLOR {
#if 1
    float3 c = tex2D(ScnSamp, coord).rgb;
    c += tex2D(BloomSamp1Y, coord).rgb;
    c += tex2D(BloomSamp2Y, coord).rgb;
    c += tex2D(BloomSamp3Y, coord).rgb;
    c += tex2D(BloomSamp4Y, coord).rgb;
#else
    float3 c = tex2D(BloomSamp0, coord).rgb;
#endif
    return float4(c, 1.0);
}

//-------------------------------------------------------------------------------------------------

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

        "RenderColorTarget0=BloomMap0;"
	    "RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
	    "Pass=ExtractBrightArea;"

#define DEFINE_BLUR_SCRIPT(x_pass, y_pass, x_map, y_map) \
        "RenderColorTarget0=" x_map ";"                  \
	    "RenderDepthStencilTarget=DepthBuffer;"          \
		"ClearSetColor=ClearColor;"                      \
		"ClearSetDepth=ClearDepth;"                      \
		"Clear=Color;"                                   \
		"Clear=Depth;"                                   \
	    "Pass=" x_pass ";"                               \
                                                         \
        "RenderColorTarget0=" y_map ";"                  \
	    "RenderDepthStencilTarget=DepthBuffer;"          \
		"ClearSetColor=ClearColor;"                      \
		"ClearSetDepth=ClearDepth;"                      \
		"Clear=Color;"                                   \
		"Clear=Depth;"                                   \
	    "Pass=" y_pass ";"

        DEFINE_BLUR_SCRIPT("Blur1X", "Blur1Y", "BloomMap1X", "BloomMap1Y")
        DEFINE_BLUR_SCRIPT("Blur2X", "Blur2Y", "BloomMap2X", "BloomMap2Y")
        DEFINE_BLUR_SCRIPT("Blur3X", "Blur3Y", "BloomMap3X", "BloomMap3Y")
        DEFINE_BLUR_SCRIPT("Blur4X", "Blur4Y", "BloomMap4X", "BloomMap4Y")

        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "Pass=Sum;"
    ;
> {
    pass ExtractBrightArea < string Script = "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS(1.0);
        PixelShader  = compile ps_3_0 ExtractBrightAreaPS();
    }

    pass Sum < string Script = "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 VS(1.0);
        PixelShader  = compile ps_3_0 SumPS();
    }

#define DEFINE_BLUR_PASS(x_pass, y_pass, in_samp, x_samp, in_ratio, out_ratio) \
    pass x_pass < string Script = "Draw=Buffer;"; > {              \
        AlphaBlendEnable = FALSE;                                  \
        VertexShader = compile vs_3_0 VS(in_ratio);                \
        PixelShader  = compile ps_3_0 XBlurPS(in_samp, in_ratio);  \
    }                                                              \
    pass y_pass < string Script = "Draw=Buffer;"; > {              \
        AlphaBlendEnable = FALSE;                                  \
        VertexShader = compile vs_3_0 VS(out_ratio);               \
        PixelShader  = compile ps_3_0 YBlurPS(x_samp, out_ratio);  \
    }

    DEFINE_BLUR_PASS(Blur1X, Blur1Y, BloomSamp0,  BloomSamp1X, BloomMapViewportRatio[0], BloomMapViewportRatio[1])
    DEFINE_BLUR_PASS(Blur2X, Blur2Y, BloomSamp1Y, BloomSamp2X, BloomMapViewportRatio[1], BloomMapViewportRatio[2])
    DEFINE_BLUR_PASS(Blur3X, Blur3Y, BloomSamp2Y, BloomSamp3X, BloomMapViewportRatio[2], BloomMapViewportRatio[3])
    DEFINE_BLUR_PASS(Blur4X, Blur4Y, BloomSamp3Y, BloomSamp4X, BloomMapViewportRatio[3], BloomMapViewportRatio[4])
}
