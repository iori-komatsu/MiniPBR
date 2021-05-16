#include <Material/Base.fxsub>
#include <Shader/Curvature.fxsub>

float3 ShaderSurface(
    float3 worldPos,
    float3 baseColor,
    float3 normal,
    float3 viewDir,
    float3 lightDir,
    float3 lightIrradiance,
    uniform bool selfShadow
) {
    return Curvature(worldPos, normal);
}
