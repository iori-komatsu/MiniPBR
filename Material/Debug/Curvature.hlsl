#include <Material/Base.fxsub>
#include <Shader/Curvature.fxsub>

float _SubsurfaceScatteringScale : CONTROLOBJECT < string name="SkinController.pmx"; string item="”ç‰ºŽU—"; >;
static const float SubsurfaceScatteringScale = lerp(1.0, 20.0, _SubsurfaceScatteringScale);

float3 ShaderSurface(
    float3 worldPos,
    float3 baseColor,
    float3 normal,
    float3 viewDir,
    float3 lightDir,
    float3 lightIrradiance,
    uniform bool selfShadow
) {
    return Curvature(worldPos, normal) * SubsurfaceScatteringScale;
}
