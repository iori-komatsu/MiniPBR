#include <Material/Base.fxsub>

float2 Curvature(float3 worldPos, float3 normal) {
    float3 dPdx = ddx(worldPos);
    float3 dPdy = ddy(worldPos);
    float3 dNdx = ddx(normal);
    float3 dNdy = ddy(normal);
    float cx = length(dPdx + dNdx) / length(dPdx) - 1;
    float cy = length(dPdy + dNdy) / length(dPdy) - 1;
    return float2(cx, cy);
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
    float2 c = Curvature(worldPos, normal);
    return 0.2 * float3(c.x, c.y, 0);
}
