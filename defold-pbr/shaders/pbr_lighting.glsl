#ifndef PBR_LIGHTING
#define PBR_LIGHTING
	#define LIGHT_MAX_COUNT        4
	#define LIGHT_TYPE_DIRECTIONAL 0
	#define LIGHT_TYPE_POINT       1

	#ifdef LIGHT_PUNCTUAL
		uniform mat4 u_light_data[LIGHT_MAX_COUNT];
	#endif

	#include "/defold-pbr/shaders/pbr_input.glsl"

	#define GET_LIGHT_POSITION(light_index)  u_light_data[light_index][0].xyz
	#define GET_LIGHT_DIRECTION(light_index) u_light_data[light_index][1].xyz
	#define GET_LIGHT_COLOR(light_index)     u_light_data[light_index][2].xyz
	#define GET_LIGHT_TYPE(light_index)      int(u_light_data[light_index][3][0])
	#define GET_LIGHT_INTENSITY(light_index) u_light_data[light_index][3][1]

	struct Light
	{
		int type;
		vec3 position;
		vec3 direction;
	};

	struct LightingInfo
	{
		vec3 diffuse;
		vec3 specular;
		float occlusion;
		float occlusionStrength;
	};

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
		return textureCube(tex_diffuse_irradiance, n).rgb;
	}

	vec4 getSpecularSample(vec3 reflection, float lod)
	{
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

		return vec3(f_ab,0.0) + 0.0000001 * (FmsEms + k_D); // * irradiance;
	}

	vec3 getIBLRadianceGGX(vec3 n, vec3 v, float roughness, vec3 F0, float specularWeight)
	{
		// TODO
		const float u_MipCount = 9.0;

		float NdotV = clampedDot(n, v);
		float lod = roughness * float(u_MipCount - 1.0);
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

		// Invastigate: FssEss is causing a spherical artifact sometimes
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
				light_diffuse += l_intensity * l_color * NdotL *  BRDF_lambertian(mat.f0, mat.f90, mat.diffuseColor, mat.specularWeight, VdotH);
				light_specular += l_intensity * l_color * NdotL * BRDF_specularGGX(mat.f0, mat.f90, mat.alphaRoughness, mat.specularWeight, VdotH, NdotL, NdotV, NdotH);
			}
		}
		#endif

		LightingInfo light_info;
		light_info.diffuse  = light_diffuse;
		light_info.specular = light_specular;

		light_info.occlusion = 1.0;
		light_info.occlusionStrength = 1.0;

		if (params.hasOcclusionTexture)
		{
			light_info.occlusion = texture2D(tex_occlusion, var_texcoord0).r;
		}

		return light_info;
	}

	vec3 applyOcclusion(PBRParams params, LightingInfo lightInfo, vec3 colorIn)
	{
		return mix(colorIn, colorIn * lightInfo.occlusion, lightInfo.occlusionStrength);
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
#endif
