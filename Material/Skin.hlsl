#include <Material/Base.fxsub>
#include <Shader/ShadowMap/Sampling.fxsub>
#include <Shader/Curvature.fxsub>

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
    float v = 1.0 - saturate(Curvature(worldPos, normal));
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
    const float minLightVisibility = 0.3;
    float lightVisibility;
    if (selfShadow) {
        lightVisibility = lerp(minLightVisibility, 1.0, CastShadow(worldPos, dot(normal, lightDir)));
    } else {
        lightVisibility = 1;
    }

    float3 h = normalize(viewDir + lightDir);
    float dotNL = saturate(dot(normal, lightDir));
    float dotNV = saturate(dot(normal, viewDir));
    float dotNH = saturate(dot(normal, h));
    float dotVH = saturate(dot(viewDir, h));

    const float specularRoughness = 0.35;
    const float diffuseRoughness = 0.9;
    const float f0 = 0.04;

    float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, specularRoughness, f0);

    float3 scatterCoeff = SubsurfaceScattering(dot(normal, lightDir), worldPos, normal);
    float3 fDiffuse = OrenNayarDiffuseBRDF(
        dot(normal, lightDir),
        dot(normal, viewDir),
        dot(lightDir, viewDir),
        baseColor,
        diffuseRoughness) * scatterCoeff;

    return fSpecular * lightIrradiance * lightVisibility
         + fDiffuse * lightIrradiance * lightVisibility
         + AmbientIrradiance * baseColor;
}
