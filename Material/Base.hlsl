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

// ライトの visibility を返す。
float CastShadow(float4 lightClipPos, uniform bool selfShadow) {
	if (!selfShadow) {
		return 1.0;
	}

	float3 ndcPos = lightClipPos.xyz / lightClipPos.w;
	float2 uv = ndcPos.xy * float2(1, -1) * 0.5 + 0.5;

	// シャドウマップの外にあるならば 1.0 を返す
	if (any(saturate(uv) != uv)) {
		return 1.0;
	}

	// 参考文献:
	// * opengl-tutorial "チュートリアル16：シャドウマッピング"
	//   http://www.opengl-tutorial.org/jp/intermediate-tutorials/tutorial-16-shadow-mapping/

	float objectDepth = ndcPos.z;

	const int N_SAMPLES = 5;
	const float2 POISSON_DISK[5] = {
		float2(          0,           0),
		float2(-0.94201624, -0.39906216),
		float2( 0.94558609, -0.76890725),
		float2(-0.09418410, -0.92938870),
		float2( 0.34495938,  0.29387760),
	};

	// uv の周りをサンプリングしてどれぐらい影になっているかを調べる
	float shadow = 0.0;
	[unroll]
	for (int i = 0; i < N_SAMPLES; ++i) {
		float2 offset = POISSON_DISK[i] / 1000.0;
		float lightDepth = tex2D(ShadowBufferSampler, uv + offset).r;

		const float bias = 0.001;
		if (lightDepth < objectDepth - bias) {
			shadow += 1.0;
		}
	}
	return 1.0 - shadow / N_SAMPLES;
}

float3 ShaderSurface(
	float3 baseColor,
	float3 normal,
	float3 viewDir,
	float3 lightDir,
	float3 lightIrradiance,
	float4 lightClipPos,
	uniform bool selfShadow
) {
	float3 h = normalize(viewDir + lightDir);
	float dotNL = saturate(dot(normal, lightDir));
	float dotNV = saturate(dot(normal, viewDir));
	float dotNH = saturate(dot(normal, h));
	float dotLH = saturate(dot(lightDir, h));
	float dotVH = saturate(dot(viewDir, h));

	float lightVisibility = CastShadow(lightClipPos, selfShadow);

	const float roughness = 0.4;
	const float f0 = 0.04;
	float3 fSpecular = SpecularBRDF(dotNL, dotNV, dotNH, dotVH, roughness, f0);
	float3 fDiffuse = DiffuseBRDF(dotNL, dotNV, dotLH, baseColor, roughness);

	return (fSpecular + fDiffuse) * lightIrradiance * lightVisibility
	     + AmbientColor * baseColor;
}

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
	float3 lightIrradiance = LightColor;
	float3 outColor = ShaderSurface(
		baseColor.rgb,
		normalize(normal),
		normalize(viewDir),
		-LightDir,
		lightIrradiance,
		lightClipPos,
		selfShadow
	);
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
