#include <Shader/PostEffectCommon.fxsub>
#include <Shader/Math.fxsub>
#include <Shader/Parameter/Viewport.fxsub>
#include <Shader/Parameter/Geometry.fxsub>
#include <Shader/ColorSpace.fxsub>

// �p�����[�^����p�I�u�W�F�N�g
float3 XYZ  : CONTROLOBJECT < string name = "(self)"; string item = "XYZ";  >; // ���W
float3 Rxyz : CONTROLOBJECT < string name = "(self)"; string item = "Rxyz"; >; // ��]
float  Si   : CONTROLOBJECT < string name = "(self)"; string item = "Si";   >; // �X�P�[��
float  Tr   : CONTROLOBJECT < string name = "(self)"; string item = "Tr";   >; // ���ߓx

// �t�H�O�̐F
static float3 FogColor = HSV2RGB(float3(0.6, 0.2, 0.8) + Rxyz);

// �z���W��
static float Absorptivity = 0.00003 * exp(XYZ.x * 0.01);

// �W���Ƒ�C�̖��x�̊֌W
static float DensityFactor = 0.000048 * exp(XYZ.y * 0.05);

// ���̐F�ƃt�H�O�F��������Ƃ��ɍŒ�ł����̊��������͌��̐F���c��
static float MinOriginalColorMixRatio = saturate(XYZ.z * 0.01);

// �X�P�[�� (�A�N�Z�T���� Si ��UI�Ŏw�肳�ꂽ�l��10�{���擾�����̂ŁA���Ƃɖ߂�)
static float Scale = Si * 0.1;

//-------------------------------------------------------------------------------------------------

shared texture2D DepthMap : OFFSCREENRENDERTARGET <
    string Description = "MiniPBR DepthMap";
    string Format = "R32F";
    float2 ViewportRatio = {1.0, 1.0};
    int    Miplevels = 1;
    float4 ClearColor = {0.0, 0.0, 0.0, 1.0};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
    string DefaultEffect =
        "self = hide;"
        "* = DepthMap.fx";
>;
sampler2D DepthSamp = sampler_state {
    texture   = <DepthMap>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

//-------------------------------------------------------------------------------------------------

float4 VS(
    float4 pos : POSITION,
    float2 coord : TEXCOORD0,
    out float2 oCoord: TEXCOORD0
) : POSITION {
    oCoord = ViewportCoordToTexelCoord(coord);
    return pos;
}

// World��Ԃɂ����郌�C�̌��������߂�B
float3 GetRayDir(float2 coord) {
    float2 p = (coord.xy - 0.5) * 2.0;
    return normalize(
          ViewMatrix._13_23_33 / ProjectionMatrix._33
        + ViewMatrix._11_21_31 * p.x / ProjectionMatrix._11
        - ViewMatrix._12_22_32 * p.y / ProjectionMatrix._22
    );
}

float4 PS(float2 coord: TEXCOORD0) : COLOR {
    float4 inColor = tex2D(ScnSamp, coord);
    float depth = tex2D(DepthSamp, coord).r;

    if (depth == 0) {
        return inColor;
    }

    float3 rayDir = GetRayDir(coord);
    float3 targetPos = CameraPos + rayDir * depth;

    // Lambert-Beer �̖@���ɂ��ƁA���ˌ��̋����� I�A���ߌ��̋����� T�A�Ώۂ̓_�܂ł̋����� d �Ƃ����
    //   log T = log I - �Ã�d
    // �Ƃ����֌W�����藧�B������ �� �͋z���W���ŁA�� �͑�C�̖��x�B
    // ���̎��ł͑�C�̖��x�����ł��邱�Ƃ����肵�Ă��邪�A���ۂɂ͕W���ɂ���đ�C�̖��x���ς��B
    // �����ŁA��C�̖��x���ȉ��̂悤�ɕW�� h �̊֐��Ƃ��ĕ\����Ɖ��肷��B
    //   ��(h) = exp(-Dh)      (D �͒萔)
    // ���̎��� Lambert-Beer �̎��̓���Đϕ�����Ɠ��ߌ��̋��������߂���B
    //   log T = ��[0,1] (log I - �� ��(lerp(h_t, h_c, x)) d) dx
    //         = log I + (��/D) d (exp(-D h_c) - exp(-D h_t)) / (h_c - h_t)
    // ������ h_t �͑Ώۂ̓_�̕W����\���Ah_c �̓J�����̕W����\���B

    float h_c = max(CameraPos.y * Scale, 0);
    float h_t = max(targetPos.y * Scale, 0);
    float dist = depth * Scale;

    float a; // ���̋z���x�B�l��� -�� ���� 0 �܂�
    if (abs(h_t - h_c) < 0.01) {
        a = -Absorptivity * exp(-DensityFactor * h_t) * dist;
    } else {
        a = (Absorptivity / DensityFactor) * dist
            * (exp(-DensityFactor * h_c) - exp(-DensityFactor * h_t))
            / (h_c - h_t);
    }

    float mixRatio = max(exp(a), MinOriginalColorMixRatio);
    float3 outColor = lerp(FogColor, inColor.rgb, mixRatio);
    return float4(outColor, inColor.a);
}

float4 ClearColor = float4(0, 0, 0, 0);
float ClearDepth = 1.0;

technique postprocessTest <
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
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
