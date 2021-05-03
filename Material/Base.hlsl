#pragma warning(disable : 3571)
#pragma warning(disable : 4717)

#include <Shader/ColorSpace.fxsub>
#include <Shader/BRDF.fxsub>

// LightColor �ɑ΂��� AmbientColor �̑傫��
static const float AmbientCoeff = 0.2;

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDir  : DIRECTION < string Object = "Light"; >;
float3   CameraPos : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
// ���C�g�F
float3   LightAmbient      : AMBIENT < string Object = "Light"; >;
static float3 LightColor   = srgb2linear(LightAmbient) * 4.0;
static float3 AmbientColor = LightColor * AmbientCoeff;

// �e�N�X�`���ގ����[�t�l
float4   TextureAddValue : ADDINGTEXTURE;
float4   TextureMulValue : MULTIPLYINGTEXTURE;

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
#define  SKII1    1500
#define  SKII2    8000

// �I�u�W�F�N�g�̃e�N�X�`��
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

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler ShadowBufferSampler : register(s0);

// ���_�V�F�[�_
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
	// �J�������_�̃��[���h�r���[�ˉe�ϊ�
	oPos = mul(pos, WorldViewProjMatrix);

	// �J�����Ƃ̑��Έʒu
	oViewDir = CameraPos - mul(pos, WorldMatrix).rgb;
	// ���_�@��
	oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

	if (selfShadow) {
		// ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
		oLightClipPos = mul(pos, LightWorldViewProjMatrix);
	} else {
		oLightClipPos = (float4)0;
	}

	// �e�N�X�`�����W
	oTexCoord = texCoord;
}

// ���C�g�� visibility ��Ԃ��B
float CastShadow(float4 lightClipPos, uniform bool selfShadow) {
	if (!selfShadow) {
		return 1.0;
	}

	float3 ndcPos = lightClipPos.xyz / lightClipPos.w;
	float2 uv = ndcPos.xy * float2(1, -1) * 0.5 + 0.5;

	// �V���h�E�}�b�v�̊O�ɂ���Ȃ�� 1.0 ��Ԃ�
	if (any(saturate(uv) != uv)) {
		return 1.0;
	}

	// �Q�l����:
	// * opengl-tutorial "�`���[�g���A��16�F�V���h�E�}�b�s���O"
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

	// uv �̎�����T���v�����O���Ăǂꂮ�炢�e�ɂȂ��Ă��邩�𒲂ׂ�
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
		// �e�N�X�`���ގ����[�t
		texColor.rgb = lerp(
			1,
			texColor.rgb * TextureMulValue.rgb + TextureAddValue.rgb,
			TextureMulValue.a + TextureAddValue.a);
		baseColor *= texColor;
	}
	return float4(srgb2linear(baseColor.rgb), baseColor.a);
}

// �s�N�Z���V�F�[�_
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
