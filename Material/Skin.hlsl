#define CONTROLLER_NAME "SkinController.pmx"

#define PRE_INTEGRATED_SKIN_LUT_PATH "Texture/PreIntegratedSkinLUT.png"

#define USE_NORMAL_MAP
#define NORMAL_MAP_PATH "Texture/NM-Skin01.png"
static const float NormalMapRepeat = 5;

#include <Shader/Material/PreIntegratedSkin.fxsub>
