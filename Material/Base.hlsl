#pragma warning(disable : 3571)
#pragma warning(disable : 4717)

#include <Shader/ColorSpace.fxsub>
#include <Shader/BRDF.fxsub>

// LightColor に対する AmbientColor の大きさ
static const float AmbientCoeff = 0.2;

// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDir  : DIRECTION < string Object = "Light"; >;
float3   CameraPos : POSITION  < string Object = "Camera"; >;

// マテリアル色
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
// ライト色
float3   LightAmbient      : AMBIENT < string Object = "Light"; >;
static float3 LightColor   = srgb2linear(LightAmbient) * 4.0;
static float3 AmbientColor = LightColor * AmbientCoeff;

// テクスチャ材質モーフ値
float4   TextureAddValue : ADDINGTEXTURE;
float4   TextureMulValue : MULTIPLYINGTEXTURE;

bool     parthf;   // パースペクティブフラグ
bool     transp;   // 半透明フラグ
#define  SKII1    1500
#define  SKII2    8000

// オブジェクトのテクスチャ
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjectTextureSampler = sampler_state {
	texture = <ObjectTexture>;
	MINFILTER = LINEAR;
	MAGFILTER = LINEAR;
	MIPFILTER = LINEAR;
	ADDRESSU  = WRAP;
	ADDRESSV  = WRAP;
};

//---------------------------------------------------------------------------------------------

// シャドウバッファのサンプラ。"register(s0)"なのはMMDがs0を使っているから
sampler ShadowBufferSampler : register(s0);

// 頂点シェーダ
void MainVS(
	in float4 pos : POSITION,
	in float3 normal : NORMAL,
	in float2 texCoord : TEXCOORD0,
	in uniform bool useTexture,
	in uniform bool selfShadow,
	out float4 oPos : POSITION,
	out float4 oLightClipPos : TEXCOORD0,
	out float2 oTexCoord : TEXCOORD1,
	out float3 oNormal : TEXCOORD2,
	out float3 oViewDir : TEXCOORD3
) {
	// カメラ視点のワールドビュー射影変換
	oPos = mul(pos, WorldViewProjMatrix);

	// カメラとの相対位置
	oViewDir = CameraPos - mul(pos, WorldMatrix).rgb;
	// 頂点法線
	oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

	if (selfShadow) {
		// ライト視点によるワールドビュー射影変換
		oLightClipPos = mul(pos, LightWorldViewProjMatrix);
	} else {
		oLightClipPos = (float4)0;
	}

	// テクスチャ座標
	oTexCoord = texCoord;
}

float3 CalculateLight(
	float4 lightClipPos,
	uniform bool selfShadow
) {
	if (!selfShadow) {
		return LightColor;
	}

	// シャドウマップの座標に変換
	lightClipPos /= lightClipPos.w;
	float2 shadowMapCoord = float2(
		(1 + lightClipPos.x) * 0.5,
		(1 - lightClipPos.y) * 0.5);

	if (any(saturate(shadowMapCoord) != shadowMapCoord)) {
		return LightColor;
	}

	float lightDepth = max(lightClipPos.z - tex2D(ShadowBufferSampler, shadowMapCoord).r, 0);
	float comp;
	if (parthf) {
		// セルフシャドウ mode2
		comp = 1 - saturate(lightDepth * SKII2 * shadowMapCoord.y - 0.3);
	} else {
		// セルフシャドウ mode1
		comp = 1 - saturate(lightDepth * SKII1 - 0.3);
	}
	return lerp(0, LightColor, comp);
}

float3 ShaderSurface(
	float3 baseColor,
	float3 normal,
	float3 viewDir,
	float3 lightColor
) {
	float3 h = normalize(viewDir + -LightDir);
	float dotNL = saturate(dot(normal, -LightDir));
	float dotNV = saturate(dot(normal, viewDir));
	float dotNH = saturate(dot(normal, h));
	float dotLH = saturate(dot(-LightDir, h));
	float dotVH = saturate(dot(viewDir, h));

	const float roughness = 0.4;
	float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, roughness, 0.04);
	float3 fDiffuse = DiffuseBRDF(dotNL, dotNV, dotLH, baseColor, roughness);

	return (fSpecular + fDiffuse) * lightColor + AmbientColor * baseColor;
}

float4 BaseColor(float2 tex, uniform bool useTexture);

// ピクセルシェーダ
float4 MainPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 viewDir : TEXCOORD3,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
	float4 baseColor = BaseColor(tex, useTexture);
	float3 lightColor = CalculateLight(lightClipPos, selfShadow);
	float3 outColor = ShaderSurface(baseColor.rgb, normalize(normal), normalize(viewDir), lightColor);
	return float4(linear2srgb(outColor), baseColor.a);
}

//---------------------------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass, usetexture, selfshadow) \
	technique name < string MMDPass = mmdpass; bool UseTexture = usetexture; > { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 MainVS(usetexture, selfshadow); \
			PixelShader  = compile ps_3_0 MainPS(usetexture, selfshadow); \
		} \
	}

MAIN_TEC(MainTec0, "object", false, false)
MAIN_TEC(MainTec1, "object", true, false)
MAIN_TEC(MainTecBS0, "object_ss", false, true)
MAIN_TEC(MainTecBS1, "object_ss", true, true)

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float4 baseColor = float4(MaterialAmbient, MaterialDiffuse.a);
	if (useTexture) {
		float4 texColor = tex2D(ObjectTextureSampler, tex);
		// テクスチャ材質モーフ
		texColor.rgb = lerp(
			1,
			texColor.rgb * TextureMulValue.rgb + TextureAddValue.rgb,
			TextureMulValue.a + TextureAddValue.a);
		baseColor *= texColor;
	}
	return float4(srgb2linear(baseColor.rgb), baseColor.a);
}
