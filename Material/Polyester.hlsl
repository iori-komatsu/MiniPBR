static const float ReduceShadow = 0.1;
static const float Roughness = 0.3;
static const float Metallic = 0.0;
static const float Reflectance = 0.5;

#define USE_NORMAL_MAP
// https://3dtextures.me/2020/02/11/fabric-polyester-002/
#define NORMAL_MAP_PATH "Texture/Fabric_Polyester_002_normal.jpg"
static const float NormalMapRepeat = 5;

#include <Shader/Material/Standard.fxsub>
