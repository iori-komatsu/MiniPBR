#include <Shader/Material/Base.fxsub>
#include <Shader/BRDF.fxsub>
#include <Shader/ShadowMap/Sampling.fxsub>

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
    float dotNL = dot(normal, lightDir);
    float dotNV = saturate(dot(normal, viewDir)); // NÅEV < 0 ÇÕåvéZåÎç∑Ç≈ÇµÇ©Ç†ÇËÇ¶Ç»Ç¢ÇÃÇ≈ saturate Ç∑ÇÈ
    float dotNH = dot(normal, h);
    float dotLH = dot(lightDir, h);
    float dotVH = dot(viewDir, h);
    float dotLV = dot(lightDir, viewDir);

    const float specularRoughness = 0.35;
    const float diffuseRoughness = 0.85;
    const float f0 = 0.04;
    float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, specularRoughness, f0);
    float3 fDiffuse = DiffuseBRDF(dotNL, dotNV, dotLV, dotLH, baseColor, diffuseRoughness);

    return (fSpecular + fDiffuse) * saturate(dotNL) * lightIrradiance * lightVisibility
         + AmbientIrradiance * baseColor;
}
