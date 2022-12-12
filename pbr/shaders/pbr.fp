varying highp   vec4 var_position_world;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec2 var_texcoord1;
varying mediump mat3 var_TBN;

uniform mediump vec4 u_camera_position;
uniform mediump vec4 u_light_direction;

// Material inputs
uniform lowp sampler2D tex_albedo;
uniform lowp sampler2D tex_normal;
uniform lowp sampler2D tex_metallic_roughness;
uniform lowp sampler2D tex_occlusion;
uniform lowp sampler2D tex_emissive;

uniform lowp vec4 u_pbr_params_0;
uniform lowp vec4 u_pbr_params_1;
uniform lowp vec4 u_pbr_params_2;
uniform lowp vec4 u_pbr_debug_params;

#define DEBUG_MODE_NONE       0
#define DEBUG_MODE_BASE_COLOR 1
#define DEBUG_MODE_TC_0       2
#define DEBUG_MODE_TC_1       3
#define DEBUG_MODE_ROUGHNESS  4

#define USE_DEBUG_DRAWING
#define USE_ROUGHNESS_MAP

const float M_PI = 3.141592653589793;

struct PBRParams
{
	vec4 baseColor;
	float metallic;
	float roughness;
	bool hasAlbedoTexture;
	bool hasNormalTexture;
	bool hasEmissiveTexture;
	bool hasMetallicRoughnessTexture;
	bool hasOcclusionTexture;
};

struct MaterialInfo
{
	vec4  baseColor;
	float ior;
	vec3  f0;
	vec3  f90;
	float specularWeight;
	float metallic;
	float perceptualRoughness;
};

struct PBRData
{
	float NdotL;
	float NdotV;
	float NdotH;
	float LdotH;
	float VdotH;
	float alphaRoughness;
	vec3  reflectance0;
	vec3  reflectance90;
	vec3  diffuseColor;
};

vec4 applyDebugMode(vec4 color_in, MaterialInfo materialInfo, PBRData pbrData)
{
	int debug_mode = int(u_pbr_debug_params.x);
	if      (debug_mode == DEBUG_MODE_NONE)       return color_in;
	else if (debug_mode == DEBUG_MODE_BASE_COLOR) return materialInfo.baseColor;
	else if (debug_mode == DEBUG_MODE_TC_0)       return vec4(var_texcoord0, 0.0, 1.0);
	else if (debug_mode == DEBUG_MODE_TC_1)       return vec4(var_texcoord1, 0.0, 1.0);
	else if (debug_mode == DEBUG_MODE_ROUGHNESS)  return vec4(vec3(materialInfo.perceptualRoughness), 1.0);
	return color_in;
}

vec4 toLinear(vec4 nonLinearIn)
{
	vec3 linearOut = pow(nonLinearIn.rgb, vec3(2.2));
	return vec4(linearOut, nonLinearIn.a);
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

	materialInfo.f0 = mix(materialInfo.f0, materialInfo.baseColor.rgb, materialInfo.metallic);
	
	return materialInfo;
}

PBRData getPBRData(PBRParams params, MaterialInfo info)
{
	vec3 diffuseColor;
	diffuseColor  = info.baseColor.rgb * (1.0 - info.f0);
	diffuseColor *= 1.0 - info.metallic;

	float alphaRoughness = info.perceptualRoughness * info.perceptualRoughness;
	float reflectance = max(max(info.f0.r, info.f0.g), info.f0.b);

	float reflectance90 = clamp(reflectance * 25.0, 0.0, 1.0);
	vec3 specularEnvironmentR0 = info.f0.rgb;
	vec3 specularEnvironmentR90 = vec3(1.0, 1.0, 1.0) * reflectance90;

	vec3 n = getNormal(params);
	vec3 v = normalize(u_camera_position.xyz - var_position_world.xyz);    // Vector from surface point to camera
	vec3 l = normalize(u_light_direction.xyz);     // Vector from surface point to light
	vec3 h = normalize(l+v);                        // Half vector between both l and v
	vec3 reflection = -normalize(reflect(v, n));
	reflection.y *= -1.0f;

	PBRData data;
	data.NdotL = clamp(dot(n, l), 0.001, 1.0);
	data.NdotV = clamp(abs(dot(n, v)), 0.001, 1.0);
	data.NdotH = clamp(dot(n, h), 0.0, 1.0);
	data.LdotH = clamp(dot(l, h), 0.0, 1.0);
	data.VdotH = clamp(dot(v, h), 0.0, 1.0);
	data.alphaRoughness = alphaRoughness;
	data.diffuseColor = diffuseColor;
	data.reflectance0 = specularEnvironmentR0;
	data.reflectance90 = specularEnvironmentR90;
	return data;
}

float microfacetDistribution(PBRData data)
{
	float roughnessSq = data.alphaRoughness * data.alphaRoughness;
	float f = (data.NdotH * roughnessSq - data.NdotH) * data.NdotH + 1.0;
	return roughnessSq / (M_PI * f * f);
}

vec3 specularReflection(PBRData data)
{
	return data.reflectance0 + (data.reflectance90 - data.reflectance0) * pow(clamp(1.0 - data.VdotH, 0.0, 1.0), 5.0);
}

vec3 diffuse(PBRData data)
{
	return data.diffuseColor / M_PI;
}

float geometricOcclusion(PBRData data)
{
	float NdotL = data.NdotL;
	float NdotV = data.NdotV;
	float r = data.alphaRoughness;

	float attenuationL = 2.0 * NdotL / (NdotL + sqrt(r * r + (1.0 - r * r) * (NdotL * NdotL)));
	float attenuationV = 2.0 * NdotV / (NdotV + sqrt(r * r + (1.0 - r * r) * (NdotV * NdotV)));
	return attenuationL * attenuationV;
}

vec3 getLighting(PBRData data)
{
	// Calculate the shading terms for the microfacet specular shading model
	vec3 F  = specularReflection(data);
	float G = geometricOcclusion(data);
	float D = microfacetDistribution(data);

	const vec3 lightColor = vec3(1.0);
	vec3 diffuseContrib   = (1.0 - F) * diffuse(data);
	vec3 specContrib      = F * G * D / (4.0 * data.NdotL * data.NdotV);
	vec3 color            = data.NdotL * lightColor * (diffuseContrib + specContrib);
	return color;
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
	PBRParams params = getPBRParams();
	MaterialInfo materialInfo = getMaterialInfo(params);

	PBRData pbrData = getPBRData(params, materialInfo);
	vec3 lighting   = getLighting(pbrData);
	lighting        = applyOcclusion(params, lighting);
	lighting        = applyEmissive(params, lighting);

	gl_FragColor = tonemap(vec4(lighting, materialInfo.baseColor.a));

#ifdef USE_DEBUG_DRAWING
	gl_FragColor = applyDebugMode(gl_FragColor, materialInfo, pbrData);
#endif
}
