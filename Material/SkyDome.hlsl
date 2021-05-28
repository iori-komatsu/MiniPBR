#include <Shader/Material/Base.fxsub>

float3 ShaderSurface(
    float3 worldPos,
    float3 baseColor,
    float3 normal,
    float3 viewDir,
    float3 lightDir,
    float3 lightIrradiance,
    float  normalLength,
    uniform bool selfShadow
) {
    return baseColor;
}
