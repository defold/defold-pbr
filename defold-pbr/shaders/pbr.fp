#define DEBUG_MODE_NONE       0
#define DEBUG_MODE_BASE_COLOR 1
#define DEBUG_MODE_TC_0       2
#define DEBUG_MODE_TC_1       3
#define DEBUG_MODE_ROUGHNESS  4
#define DEBUG_MODE_METALLIC   5
#define DEBUG_MODE_NORMALS    6

#define USE_DEBUG_DRAWING
#define USE_ROUGHNESS_MAP

#define LIGHT_MAX_COUNT        4
#define LIGHT_TYPE_DIRECTIONAL 0
#define LIGHT_TYPE_POINT       1

#define LIGHT_IBL
//#define LIGHT_PUNCTUAL

#define M_PI 3.141592653589793

varying highp   vec4 var_position_world;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec2 var_texcoord1;
varying mediump mat3 var_TBN;

// Environment inputs
uniform lowp samplerCube tex_diffuse_irradiance;
uniform lowp samplerCube tex_prefiltered_reflection;
uniform lowp sampler2D   tex_brdflut;

// Material inputs
uniform lowp sampler2D tex_albedo;
uniform lowp sampler2D tex_normal;
uniform lowp sampler2D tex_metallic_roughness;
uniform lowp sampler2D tex_occlusion;
uniform lowp sampler2D tex_emissive;

uniform mediump vec4 u_camera_position;

#ifdef LIGHT_PUNCTUAL
uniform mat4         u_light_data[LIGHT_MAX_COUNT];
#endif

// col 0: xyz: position
// col 1: xyz: direction
// col 2: xyz: color
// col 3: x: type

#define GET_LIGHT_POSITION(light_index)  u_light_data[light_index][0].xyz 
#define GET_LIGHT_DIRECTION(light_index) u_light_data[light_index][1].xyz 
#define GET_LIGHT_COLOR(light_index)     u_light_data[light_index][2].xyz 
#define GET_LIGHT_TYPE(light_index)      int(u_light_data[light_index][3][0])
#define GET_LIGHT_INTENSITY(light_index) u_light_data[light_index][3][1]

uniform lowp vec4 u_pbr_params_0;
uniform lowp vec4 u_pbr_params_1;
uniform lowp vec4 u_pbr_params_2;
uniform lowp vec4 u_pbr_scene_params;

struct Light
{
	int type;
	vec3 position;
	vec3 direction;
};

struct PBRParams
{
	vec4 baseColor;
	float metallic;
	float roughness;
	float lightCount;
	bool hasAlbedoTexture;
	bool hasNormalTexture;
	bool hasEmissiveTexture;
	bool hasMetallicRoughnessTexture;
	bool hasOcclusionTexture;
};

struct MaterialInfo
{
	vec4  baseColor;
	vec3  diffuseColor;
	float ior;
	vec3  f0;
	vec3  f90;
	float specularWeight;
	float metallic;
	float perceptualRoughness;
	float alphaRoughness;
};

struct LightingInfo
{
	vec3 diffuse;
	vec3 specular;
};

struct PBRData
{
	vec3 vertexPositionWorld;
	vec3 vertexDirectionToCamera;
	vec3 vertexNormal;
};

vec4 applyDebugMode(vec4 color_in, MaterialInfo materialInfo, PBRData pbrData)
{
	int debug_mode = int(u_pbr_scene_params.x);
	if      (debug_mode == DEBUG_MODE_NONE)       return color_in;
	else if (debug_mode == DEBUG_MODE_BASE_COLOR) return materialInfo.baseColor;
	else if (debug_mode == DEBUG_MODE_TC_0)       return vec4(var_texcoord0, 0.0, 1.0);
	else if (debug_mode == DEBUG_MODE_TC_1)       return vec4(var_texcoord1, 0.0, 1.0);
	else if (debug_mode == DEBUG_MODE_ROUGHNESS)  return vec4(vec3(materialInfo.perceptualRoughness), 1.0);
	else if (debug_mode == DEBUG_MODE_METALLIC)   return vec4(vec3(materialInfo.metallic), 1.0);
	else if (debug_mode == DEBUG_MODE_NORMALS)    return vec4((pbrData.vertexNormal + 1) * 0.5, 1.0);
	return color_in;
}

vec4 toLinear(vec4 nonLinearIn)
{
	vec3 linearOut = pow(nonLinearIn.rgb, vec3(2.2));
	return vec4(linearOut, nonLinearIn.a);
}

vec3 fromLinear(vec3 linearIn)
{
	return pow(linearIn, vec3(1.0 / 2.2));
}

PBRParams getPBRParams()
{
	PBRParams params;
	params.baseColor                   = u_pbr_params_0;
	params.metallic                    = u_pbr_params_1[0];
	params.roughness                   = u_pbr_params_1[1];
	params.hasAlbedoTexture            = u_pbr_params_1[2] > 0.0f;
	params.hasNormalTexture            = u_pbr_params_1[3] > 0.0f;
	params.hasEmissiveTexture          = u_pbr_params_2[0] > 0.0f;
	params.hasMetallicRoughnessTexture = u_pbr_params_2[1] > 0.0f;
	params.hasOcclusionTexture         = u_pbr_params_2[2] > 0.0f;
	params.lightCount                  = u_pbr_scene_params.y;
	return params;
}

vec3 getNormal(PBRParams params)
{
	if (params.hasNormalTexture)
	{
		lowp vec3 sample_normal = texture2D(tex_normal, var_texcoord0).rgb * 2.0 - 1.0;

		vec3 q1 = dFdx(var_position_world.xyz);
		vec3 q2 = dFdy(var_position_world.xyz);
		vec2 st1 = dFdx(var_texcoord0);
		vec2 st2 = dFdy(var_texcoord0);

		vec3 N = normalize(var_normal);
		vec3 T = normalize(q1 * st2.t - q2 * st1.t);
		vec3 B = -normalize(cross(N, T));
		mat3 TBN = mat3(T, B, N);

		return normalize(TBN * sample_normal);
	}
	return var_normal;

	/*
	lowp vec3 normal = normalize(sample_normal);
	return normalize(var_TBN * normal);
	*/
}

MaterialInfo getMaterialInfo(PBRParams params)
{
	MaterialInfo materialInfo;
	materialInfo.ior                 = 1.5;
	materialInfo.f0                  = vec3(0.04);
	materialInfo.f90                 = vec3(1.0);
	materialInfo.specularWeight      = 1.0;
	materialInfo.baseColor           = params.baseColor;
	materialInfo.metallic            = params.metallic;
	materialInfo.perceptualRoughness = params.roughness;

	if (params.hasAlbedoTexture)
	{
		lowp vec4 sample_albedo = texture2D(tex_albedo, var_texcoord0);
		lowp vec4 albedo        = toLinear(sample_albedo);
		materialInfo.baseColor  = albedo * params.baseColor;
	}

	if (params.hasMetallicRoughnessTexture)
	{
		lowp vec4 sample_roughness       = texture2D(tex_metallic_roughness, var_texcoord0);
		materialInfo.perceptualRoughness = sample_roughness.g * materialInfo.perceptualRoughness;
		materialInfo.metallic            = sample_roughness.b * materialInfo.metallic;
	}

	materialInfo.f0             = mix(materialInfo.f0, materialInfo.baseColor.rgb, materialInfo.metallic);
	materialInfo.diffuseColor   = mix(materialInfo.baseColor.rgb,  vec3(0), materialInfo.metallic);
	materialInfo.alphaRoughness = materialInfo.perceptualRoughness * materialInfo.perceptualRoughness;
	
	return materialInfo;
}

PBRData getPBRData(PBRParams params, MaterialInfo info)
{
	PBRData data;
	data.vertexPositionWorld     = var_position_world.xyz;
	data.vertexDirectionToCamera = normalize(u_camera_position.xyz - var_position_world.xyz);
	data.vertexNormal            = getNormal(params);
	return data;
}

float clampedDot(vec3 x, vec3 y)
{
	return clamp(dot(x, y), 0.0, 1.0);
}

vec3 F_Schlick(vec3 f0, vec3 f90, float VdotH)
{
	return f0 + (f90 - f0) * pow(clamp(1.0 - VdotH, 0.0, 1.0), 5.0);
}

float F_Schlick(float f0, float f90, float VdotH)
{
	float x = clamp(1.0 - VdotH, 0.0, 1.0);
	float x2 = x * x;
	float x5 = x * x2 * x2;
	return f0 + (f90 - f0) * x5;
}

float F_Schlick(float f0, float VdotH)
{
	float f90 = 1.0; //clamp(50.0 * f0, 0.0, 1.0);
	return F_Schlick(f0, f90, VdotH);
}

vec3 F_Schlick(vec3 f0, float f90, float VdotH)
{
	float x = clamp(1.0 - VdotH, 0.0, 1.0);
	float x2 = x * x;
	float x5 = x * x2 * x2;
	return f0 + (f90 - f0) * x5;
}

vec3 F_Schlick(vec3 f0, float VdotH)
{
	float f90 = 1.0; //clamp(dot(f0, vec3(50.0 * 0.33)), 0.0, 1.0);
	return F_Schlick(f0, f90, VdotH);
}

vec3 BRDF_lambertian(vec3 f0, vec3 f90, vec3 diffuseColor, float specularWeight, float VdotH)
{
	// see https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
	return (1.0 - specularWeight * F_Schlick(f0, f90, VdotH)) * (diffuseColor / M_PI);
}

float V_GGX(float NdotL, float NdotV, float alphaRoughness)
{
	float alphaRoughnessSq = alphaRoughness * alphaRoughness;

	float GGXV = NdotL * sqrt(NdotV * NdotV * (1.0 - alphaRoughnessSq) + alphaRoughnessSq);
	float GGXL = NdotV * sqrt(NdotL * NdotL * (1.0 - alphaRoughnessSq) + alphaRoughnessSq);

	float GGX = GGXV + GGXL;
	if (GGX > 0.0)
	{
		return 0.5 / GGX;
	}
	return 0.0;
}

float D_GGX(float NdotH, float alphaRoughness)
{
	float alphaRoughnessSq = alphaRoughness * alphaRoughness;
	float f = (NdotH * NdotH) * (alphaRoughnessSq - 1.0) + 1.0;
	return alphaRoughnessSq / (M_PI * f * f);
}

vec3 BRDF_specularGGX(vec3 f0, vec3 f90, float alphaRoughness, float specularWeight, float VdotH, float NdotL, float NdotV, float NdotH)
{
	vec3 F = F_Schlick(f0, f90, VdotH);
	float Vis = V_GGX(NdotL, NdotV, alphaRoughness);
	float D = D_GGX(NdotH, alphaRoughness);

	return specularWeight * F * Vis * D;
}

vec3 getDiffuseLight(vec3 n)
{
	//return texture(u_LambertianEnvSampler, u_EnvRotation * n).rgb * u_EnvIntensity;
	return textureCube(tex_diffuse_irradiance, n).rgb;
}

vec4 getSpecularSample(vec3 reflection, float lod)
{
	//return textureLod(u_GGXEnvSampler, u_EnvRotation * reflection, lod) * u_EnvIntensity;
	return textureLod(tex_prefiltered_reflection, reflection, lod);
}

vec3 getIBLRadianceLambertian(vec3 n, vec3 v, float roughness, vec3 diffuseColor, vec3 F0, float specularWeight)
{
	float NdotV          = clampedDot(n, v);
	vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
	vec2 f_ab            = texture2D(tex_brdflut, brdfSamplePoint).rg;

	vec3 irradiance = getDiffuseLight(n);

	// see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
	// Roughness dependent fresnel, from Fdez-Aguera

	vec3 Fr     = max(vec3(1.0 - roughness), F0) - F0;
	vec3 k_S    = F0 + Fr * pow(1.0 - NdotV, 5.0);
	vec3 FssEss = specularWeight * k_S * f_ab.x + f_ab.y; // <--- GGX / specular light contribution (scale it down if the specularWeight is low)

	// Multiple scattering, from Fdez-Aguera
	float Ems   = (1.0 - (f_ab.x + f_ab.y));
	vec3 F_avg  = specularWeight * (F0 + (1.0 - F0) / 21.0);
	vec3 FmsEms = Ems * FssEss * F_avg / (1.0 - F_avg * Ems);
	vec3 k_D    = diffuseColor * (1.0 - FssEss + FmsEms); // we use +FmsEms as indicated by the formula in the blog post (might be a typo in the implementation)

	return (FmsEms + k_D) * irradiance;
}

vec3 getIBLRadianceGGX(vec3 n, vec3 v, float roughness, vec3 F0, float specularWeight)
{
	// TODO
	const float u_MipCount = 9;
	
	float NdotV = clampedDot(n, v);
	float lod = roughness * float(u_MipCount - 1);
	vec3 reflection = normalize(reflect(-v, n));

	vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
	vec2 f_ab = texture(tex_brdflut, brdfSamplePoint).rg;
	vec4 specularSample = getSpecularSample(reflection, lod);

	vec3 specularLight = specularSample.rgb;

	// see https://bruop.github.io/ibl/#single_scattering_results at Single Scattering Results
	// Roughness dependent fresnel, from Fdez-Aguera
	vec3 Fr = max(vec3(1.0 - roughness), F0) - F0;
	vec3 k_S = F0 + Fr * pow(1.0 - NdotV, 5.0);
	vec3 FssEss = k_S * f_ab.x + f_ab.y;

	return specularWeight * specularLight * FssEss;
}

LightingInfo getLighting(PBRData data, PBRParams params, MaterialInfo mat)
{
	vec3 light_diffuse  = vec3(0.0);
	vec3 light_specular = vec3(0.0);

#ifdef LIGHT_IBL
	light_diffuse  += getIBLRadianceLambertian(data.vertexNormal, data.vertexDirectionToCamera, mat.perceptualRoughness, mat.diffuseColor, mat.f0, mat.specularWeight);
	light_specular += getIBLRadianceGGX(data.vertexNormal, data.vertexDirectionToCamera, mat.perceptualRoughness, mat.f0, mat.specularWeight);
#endif

#ifdef LIGHT_PUNCTUAL
	for (int i=0; i < min(params.lightCount, LIGHT_MAX_COUNT); i++)
	{
		vec3 l_pos        = GET_LIGHT_POSITION(i);
		vec3 l_dir        = GET_LIGHT_DIRECTION(i);
		vec3 l_color      = GET_LIGHT_COLOR(i);
		int  l_type       = GET_LIGHT_TYPE(i);
		float l_intensity = GET_LIGHT_INTENSITY(i);
		
		vec3 l_vec;
		if (l_type == LIGHT_TYPE_DIRECTIONAL)
		{
			l_vec = -l_dir;
		}
		else
		{
			l_vec = l_pos - data.vertexPositionWorld;
		}

		// BSTF
		vec3 l      = normalize(l_vec);   // Direction from surface point to light
		vec3 h      = normalize(l + data.vertexDirectionToCamera);          // Direction of the vector between l and v, called halfway vector
		float NdotL = clampedDot(data.vertexNormal, l);
		float NdotV = clampedDot(data.vertexNormal, data.vertexDirectionToCamera);
		float NdotH = clampedDot(data.vertexNormal, h);
		float LdotH = clampedDot(l, h);
		float VdotH = clampedDot(data.vertexDirectionToCamera, h);

		if (NdotL > 0.0 || NdotV > 0.0)
		{
			light_diffuse += l_intensity * NdotL *  BRDF_lambertian(mat.f0, mat.f90, mat.diffuseColor, mat.specularWeight, VdotH);
			light_specular += l_intensity * NdotL * BRDF_specularGGX(mat.f0, mat.f90, mat.alphaRoughness, mat.specularWeight, VdotH, NdotL, NdotV, NdotH);
		}
	}
#endif

	LightingInfo light_info;
	light_info.diffuse  = light_diffuse;
	light_info.specular = light_specular;
	return light_info;
}

vec3 applyOcclusion(PBRParams params, vec3 colorIn)
{
	if (params.hasOcclusionTexture)
	{
		const float occlusionStrength = 1.0f;
		float occlusion = texture2D(tex_occlusion, var_texcoord0).r;
		return mix(colorIn, colorIn * occlusion, occlusionStrength);
	}
	return colorIn;
}

vec3 applyEmissive(PBRParams params, vec3 colorIn)
{
	if (params.hasEmissiveTexture)
	{
		vec4 emissive = toLinear(texture2D(tex_emissive, var_texcoord0));
		return colorIn + emissive.rgb;
	}
	return colorIn;
}

vec3 Uncharted2Tonemap(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	return ((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F))-E/F;
}

vec4 tonemap(vec4 color)
{
	const float exposure = 1.0f;
	const float invGamma = 1.0 / 2.2;
	
	vec3 outcol = Uncharted2Tonemap(color.rgb * 1.0);
	outcol = outcol * (1.0f / Uncharted2Tonemap(vec3(11.2f)));	
	return vec4(pow(outcol, vec3(invGamma)), color.a);
}

void main()
{
	PBRParams params          = getPBRParams();
	MaterialInfo materialInfo = getMaterialInfo(params);
	PBRData pbrData           = getPBRData(params, materialInfo);
	LightingInfo lightInfo    = getLighting(pbrData, params, materialInfo);

	vec3 lighting             = lightInfo.diffuse + lightInfo.specular;
	lighting                  = applyOcclusion(params, lighting);
	lighting                  = applyEmissive(params, lighting);
	
	gl_FragColor.rgb = fromLinear(lighting);
	gl_FragColor.a   = materialInfo.baseColor.a;

#ifdef USE_DEBUG_DRAWING
	gl_FragColor = applyDebugMode(gl_FragColor, materialInfo, pbrData);
#endif
}
