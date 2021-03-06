#include <Shader/Material/Base.fxsub>
#include <Shader/Curvature.fxsub>

float _SubsurfaceScatteringScale : CONTROLOBJECT < string name="SkinController.pmx"; string item="?牺?U??"; >;
static const float SubsurfaceScatteringScale = lerp(1.0, 10.0, _SubsurfaceScatteringScale);

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
    return Curvature(worldPos, normal) * SubsurfaceScatteringScale;
}
