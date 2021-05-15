#include <Shader/PostEffectCommon.fxsub>
#include <Shader/Parameter/Viewport.fxsub>

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
    float4 inColor = tex2D(ScnSamp, coord);
    return float4(inColor.rgb, inColor.a);
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
