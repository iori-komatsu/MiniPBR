#include <Shader/Parameter/Geometry.fxsub>
#include <Shader/Parameter/Viewport.fxsub>
#include <Shader/ColorSpace.fxsub>

shared texture2D ShadowMap : OFFSCREENRENDERTARGET;
sampler2D ShadowSamp = sampler_state {
    texture   = <ShadowMap>;
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
	oTexCoord = texCoord + ViewportOffset;
}

// ピクセルシェーダ
float4 MainPS(float2 texCoord : TEXCOORD0) : COLOR0 {
    // シャドウマップの内容を描画
    float depth = tex2D(ShadowSamp, texCoord).r;
    if (depth == 0.0) {
        return float4(0.2, 0.2, 0.5, 1);
    }
    float3 outColor = float3(depth, depth, depth);
	return float4(linear2srgb(outColor), 1.0);
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
