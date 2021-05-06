#include <Shader/Common.fxsub>
#include <Shader/BRDF.fxsub>
#include <Shader/ColorSpace.fxsub>
#include <Shader/Parameter/Geometry.fxsub>
#include <Shader/Parameter/Light.fxsub>
#include <Shader/Parameter/Material.fxsub>
#include <Shader/ShadowMap/Sampling.fxsub>

// LightColor に対する AmbientColor の大きさ
static const float AmbientCoeff = 0.2;

static float3 LightIrradiance = 6.0 * LightColor;
static float3 AmbientIrradiance = LightIrradiance * AmbientCoeff;

bool     parthf;   // パースペクティブフラグ
bool     transp;   // 半透明フラグ
#define  SKII1    1500
#define  SKII2    8000

// オブジェクトのテクスチャ
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjectTextureSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

//---------------------------------------------------------------------------------------------

// 頂点シェーダ
void MainVS(
    in float4 pos : POSITION,
    in float3 normal : NORMAL,
    in float2 texCoord : TEXCOORD0,
    in uniform bool useTexture,
    in uniform bool selfShadow,
    out float4 oPos : POSITION,
    out float3 oWorldPos : TEXCOORD0,
    out float2 oTexCoord : TEXCOORD1,
    out float3 oNormal : TEXCOORD2,
    out float3 oViewDir : TEXCOORD3
) {
    // カメラ視点のワールドビュー射影変換
    oPos = mul(pos, WorldViewProjMatrix);

    // ワールド座標
    oWorldPos = mul(pos, WorldMatrix).xyz;

    // カメラとの相対位置
    oViewDir = CameraPos - mul(pos, WorldMatrix).rgb;
    // 頂点法線
    oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

    // テクスチャ座標
    oTexCoord = texCoord;
}

float3 ShaderSurface(
    float3 worldPos,
    float3 baseColor,
    float3 normal,
    float3 viewDir,
    float3 lightDir,
    float3 lightIrradiance,
    uniform bool selfShadow
) {
    float3 h = normalize(viewDir + lightDir);
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, h));
    float dotLH = saturate(dot(lightDir, h));
    float dotVH = saturate(dot(viewDir, h));

    const float minLightVisibility = 0.3;
    float lightVisibility;
    if (selfShadow) {
        lightVisibility = lerp(minLightVisibility, 1.0, CastShadow(dotNL, worldPos));
    } else {
        lightVisibility = 1;
    }

    const float roughness = 0.4;
    const float f0 = 0.04;
    float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, roughness, f0);
    float3 fDiffuse = DiffuseBRDF(dotNL, dotNV, dotLH, baseColor, roughness);

    return (fSpecular + fDiffuse) * lightIrradiance * lightVisibility
         + AmbientIrradiance * baseColor;
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
    float4 baseColor = float4(MaterialAmbient, MaterialDiffuse.a);
    if (useTexture) {
        float4 texColor = tex2D(ObjectTextureSampler, tex);
        // テクスチャ材質モーフ
        texColor.rgb = lerp(
            1,
            texColor.rgb * TextureMulValue.rgb + TextureAddValue.rgb,
            TextureMulValue.a + TextureAddValue.a);
        baseColor *= texColor;
    }
    return float4(srgb2linear(baseColor.rgb), baseColor.a);
}

// ピクセルシェーダ
float4 MainPS(
    float3 worldPos : TEXCOORD0,
    float2 tex : TEXCOORD1,
    float3 normal : TEXCOORD2,
    float3 viewDir : TEXCOORD3,
    uniform bool useTexture,
    uniform bool selfShadow
) : COLOR0 {
    float4 baseColor = BaseColor(tex, useTexture);
    float3 outColor = ShaderSurface(
        worldPos,
        baseColor.rgb,
        normalize(normal),
        normalize(viewDir),
        -LightDir,
        LightIrradiance,
        selfShadow
    );
    return float4(linear2srgb(outColor), baseColor.a);
}

//---------------------------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass, usetexture, selfshadow) \
    technique name < string MMDPass = mmdpass; bool UseTexture = usetexture; > { \
        pass DrawObject { \
            VertexShader = compile vs_3_0 MainVS(usetexture, selfshadow); \
            PixelShader  = compile ps_3_0 MainPS(usetexture, selfshadow); \
        } \
    }

MAIN_TEC(MainTec0, "object", false, false)
MAIN_TEC(MainTec1, "object", true, false)
MAIN_TEC(MainTecBS0, "object_ss", false, true)
MAIN_TEC(MainTecBS1, "object_ss", true, true)
