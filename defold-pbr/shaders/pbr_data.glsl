#ifndef PBR_DATA
#define PBR_DATA

	#include "/defold-pbr/shaders/pbr_input.glsl"
	#include "/defold-pbr/shaders/pbr_debug.glsl"

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
		params.lightCount                  = GET_LIGHT_COUNT();
		return params;
	}

	vec3 getNormal(PBRParams params)
	{
	#ifdef USE_DEBUG_DRAWING
		if (GET_DEBUG_MODE() == DEBUG_MODE_NORMALS)
		{
			return var_normal;
		}

		if (GET_DEBUG_MODE() == DEBUG_MODE_TANGENTS)
		{
			return var_tangent;
		}

		if (GET_DEBUG_MODE() == DEBUG_MODE_BITANGENTS)
		{
			return cross(var_normal, var_tangent);
		}
	#endif

		if (params.hasNormalTexture)
		{
			lowp vec3 sample_normal = texture2D(tex_normal, var_texcoord0).rgb;

		#ifdef USE_DEBUG_DRAWING
			if (GET_DEBUG_MODE() == DEBUG_MODE_NORMAL_TEXTURE)
			{
				return sample_normal;
			}
		#endif

			sample_normal = sample_normal * 2.0 - 1.0;
			vec3 N = normalize(var_normal);
			vec3 T = normalize(var_tangent); // normalize(q1 * st2.t - q2 * st1.t);
			vec3 B = -normalize(cross(N, T));
			mat3 TBN = mat3(T, B, N);
			return normalize(TBN * sample_normal);
		}

		return var_normal;
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

#endif // PBR_DATA
