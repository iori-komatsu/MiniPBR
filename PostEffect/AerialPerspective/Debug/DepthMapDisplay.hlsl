#include <Shader/Common.fxsub>
#include <Shader/Parameter/Geometry.fxsub>
#include <Shader/Parameter/Viewport.fxsub>
#include <Shader/ColorSpace.fxsub>

shared texture2D DepthMap;
sampler2D DepthSamp = sampler_state {
    texture   = <DepthMap>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

// 頂点シェーダ
void MainVS(
    in float4 pos : POSITION,
    in float2 texCoord : TEXCOORD0,
    out float4 oPos : POSITION,
    out float2 oTexCoord : TEXCOORD0
) {
    float2 scale = ViewportSize.yx / max(ViewportSize.x, ViewportSize.y);
    float2 offset = 1 - scale;
    float2 uv = (pos.xy + 1) / 2;
    oPos = float4(scale*uv + offset, pos.zw);
    oTexCoord = ViewportCoordToTexelCoord(texCoord);
}

// ピクセルシェーダ
float4 MainPS(float2 coord : TEXCOORD0) : COLOR {
    float depth = tex2D(DepthSamp, coord).r;
    return float4(depth, depth, depth, 1);
}

//---------------------------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass) \
    technique name < string MMDPass = mmdpass; > { \
        pass DrawObject { \
            VertexShader = compile vs_3_0 MainVS(); \
            PixelShader  = compile ps_3_0 MainPS(); \
        } \
    }

MAIN_TEC(MainTec, "object")
MAIN_TEC(MainTecBS, "object_ss")
