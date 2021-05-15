#include <Material/Base.fxsub>

float3 ShaderSurface(
    float3 worldPos,
    float3 baseColor,
    float3 normal,
    float3 viewDir,
    float3 lightDir,
    float3 lightIrradiance,
    uniform bool selfShadow
) {
    const float k = 0.6; // ���邭�Ȃ肷����̂ł�����ƌ��ʂ����炷
    return k * lightIrradiance * baseColor;
}
