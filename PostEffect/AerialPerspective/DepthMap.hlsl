#include <Shader/Common.fxsub>
#include <Shader/Parameter/Geometry.fxsub>

void DepthMapVS(
    in float4 pos : POSITION,
    out float4 oPos : POSITION,
    out float oDepth : TEXCOORD0
) {
    float4 viewPos = mul(pos, WorldViewMatrix);
    oDepth = viewPos.z;
    oPos = mul(viewPos, ProjectionMatrix);
}

float4 DepthMapPS(
    in float depth : TEXCOORD0
) : COLOR {
    return float4(depth, 0, 0, 0);
}

#define DEFINE_TEC(name, mmdpass) \
    technique name<string MMDPass = mmdpass;> { \
        pass RenderShadowMap { \
            AlphaBlendEnable = false; AlphaTestEnable = false; \
            VertexShader = compile vs_3_0 DepthMapVS(); \
            PixelShader  = compile ps_3_0 DepthMapPS(); \
        } \
    }

DEFINE_TEC(ObjectTec, "object")
DEFINE_TEC(ObjectTecSS, "object_ss")

#define EMPTY_TEC(name, mmdpass) technique name<string MMDPass = mmdpass;> {}

EMPTY_TEC(EdgeTec, "edge")
EMPTY_TEC(ShadowTec, "shadow")
EMPTY_TEC(ZplotTec, "zplot")
