#include <Shader/Material/Base.fxsub>
#include <Shader/BRDF.fxsub>
#include <Shader/ShadowMap/Sampling.fxsub>
#include <Shader/Curvature.fxsub>

float _SpecularSmoothness        : CONTROLOBJECT < string name="SkinController.pmx"; string item="反射光の滑らかさ"; >;
float _DiffuseSmoothness         : CONTROLOBJECT < string name="SkinController.pmx"; string item="拡散光の滑らかさ"; >;
float _ReduceShadow              : CONTROLOBJECT < string name="SkinController.pmx"; string item="影を薄める"; >;
float _SubsurfaceScatteringScale : CONTROLOBJECT < string name="SkinController.pmx"; string item="皮下散乱"; >;

static const float SpecularRoughness = 1.0 - _SpecularSmoothness;
static const float DiffuseRoughness  = 1.0 - _DiffuseSmoothness;
static const float MinLightVisibility = _ReduceShadow;
static const float SubsurfaceScatteringScale = lerp(1.0, 20.0, _SubsurfaceScatteringScale);

texture2D PreIntegratedSkinLUT <
    string ResourceName = "../Misc/PreIntegratedSkin/LUT_Linear.png";
>;
sampler2D PreIntegratedSkinLUTSamp = sampler_state {
    Texture = <PreIntegratedSkinLUT>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float3 SubsurfaceScattering(float dotNL, float3 worldPos, float3 normal) {
    float u = dotNL * 0.5 + 0.5;
    float v = 1.0 - saturate(Curvature(worldPos, normal) * SubsurfaceScatteringScale);
    return tex2D(PreIntegratedSkinLUTSamp, float2(u, v)).rgb;
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
    float lightVisibility;
    if (selfShadow) {
        float s = CastShadow(worldPos, dot(normal, lightDir));
        lightVisibility = lerp(MinLightVisibility, 1.0, s);
    } else {
        lightVisibility = 1;
    }

    float3 h = normalize(viewDir + lightDir);
    float dotNL = dot(normal, lightDir);
    float dotNV = saturate(dot(normal, viewDir)); // N・V < 0 は計算誤差でしかありえないので saturate する
    float dotNH = dot(normal, h);
    float dotVH = dot(viewDir, h);
    float dotLH = dot(lightDir, h);
    float dotLV = dot(lightDir, viewDir);

    const float f0 = 0.04;
    float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, SpecularRoughness, f0) * saturate(dotNL);

    float3 scatterCoeff = SubsurfaceScattering(dotNL, worldPos, normal);
    float3 fDiffuse = DiffuseBRDF(
        scatterCoeff, // N･L の代わりに scatterCoeff を使う
        dotNV, dotLV, dotLH,
        baseColor,
        DiffuseRoughness) * scatterCoeff;

    return (fSpecular + fDiffuse) * lightIrradiance * lightVisibility
         + AmbientIrradiance * baseColor;
}
