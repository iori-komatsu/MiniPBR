#include <Material/Base.fxsub>
#include <Shader/BRDF.fxsub>
#include <Shader/ShadowMap/Sampling.fxsub>
#include <Shader/Curvature.fxsub>

float _SpecularSmoothness        : CONTROLOBJECT < string name="SkinController.pmx"; string item="”½ŽËŒõ‚ÌŠŠ‚ç‚©‚³"; >;
float _DiffuseSmoothness         : CONTROLOBJECT < string name="SkinController.pmx"; string item="ŠgŽUŒõ‚ÌŠŠ‚ç‚©‚³"; >;
float _ReduceShadow              : CONTROLOBJECT < string name="SkinController.pmx"; string item="‰e‚ð”–‚ß‚é"; >;
float _SubsurfaceScatteringScale : CONTROLOBJECT < string name="SkinController.pmx"; string item="”ç‰ºŽU—"; >;

static const float SpecularRoughness = 1.0 - _SpecularSmoothness;
static const float DiffuseRoughness  = 1.0 - _DiffuseSmoothness;
static const float MinLightVisibility = _ReduceShadow;
static const float SubsurfaceScatteringScale = lerp(1.0, 10.0, _SubsurfaceScatteringScale);

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
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, h));
    float dotVH = saturate(dot(viewDir, h));

    const float f0 = 0.04;
    float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, SpecularRoughness, f0);

    float3 scatterCoeff = SubsurfaceScattering(dot(normal, lightDir), worldPos, normal);
    float3 fDiffuse = DiffuseBRDF(
        scatterCoeff, // N¥L ‚Ì‘ã‚í‚è‚É scatterCoeff ‚ðŽg‚¤
        dot(normal, viewDir),
        dot(lightDir, viewDir),
        dot(lightDir, h),
        baseColor,
        DiffuseRoughness) * scatterCoeff;

    return fSpecular * lightIrradiance * lightVisibility
         + fDiffuse * lightIrradiance * lightVisibility
         + AmbientIrradiance * baseColor;
}
