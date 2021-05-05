#include <Shader/ShadowMap.fxsub>

void ShadowMapVS(
    in float4 pos : POSITION,
    out float4 oPos : POSITION,
    out float oDepth : TEXCOORD0
) {
    oPos = ShadowMapCoord(pos.xyz, oDepth);
}

float4 ShadowMapPS(
    in float depth : TEXCOORD0
) : COLOR {
    return float4(depth, 0, 0, 0);
}

technique DepthTec1<string MMDPass = "object_ss";> {
    pass RenderShadowMap {
        AlphaBlendEnable = false; AlphaTestEnable = false;
        VertexShader = compile vs_3_0 ShadowMapVS();
        PixelShader  = compile ps_3_0 ShadowMapPS();
    }
}

#define EMPTY_TEC(name, mmdpass) technique name<string MMDPass = mmdpass;> {}

EMPTY_TEC(DepthTec0, "object")
EMPTY_TEC(EdgeTec, "edge")
EMPTY_TEC(ShadowTec, "shadow")
EMPTY_TEC(ZplotTec, "zplot")
