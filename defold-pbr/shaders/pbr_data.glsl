#ifndef PBR_DATA
#define PBR_DATA

	#include "/defold-pbr/shaders/pbr_input.glsl"
	#include "/defold-pbr/shaders/pbr_debug.glsl"

	PBRParams getPBRParams()
	{
		PBRParams params;
		params.baseColor                   = u_pbr_params_0;
		params.metallic                    = u_pbr_params_1.x;
		params.roughness                   = u_pbr_params_1.y;
		params.hasAlbedoTexture            = u_pbr_params_1.z > 0.0f;
		params.hasNormalTexture            = u_pbr_params_1.w > 0.0f;
		params.hasEmissiveTexture          = u_pbr_params_2.x > 0.0f;
		params.hasMetallicRoughnessTexture = u_pbr_params_2.y > 0.0f;
		params.hasOcclusionTexture         = u_pbr_params_2.z > 0.0f;
		params.lightCount                  = PBR_LIGHT_COUNT;
		return params;
	}

	vec3 getNormal(PBRParams params)
	{
	#ifdef USE_DEBUG_DRAWING
		if (PBR_DEBUG_MODE == DEBUG_MODE_NORMALS)
		{
			return var_normal;
		}

		if (PBR_DEBUG_MODE == DEBUG_MODE_TANGENTS)
		{
			return var_tangent;
		}

		if (PBR_DEBUG_MODE == DEBUG_MODE_BITANGENTS)
		{
			return -cross(var_normal, var_tangent);
		}

		if (PBR_DEBUG_MODE == DEBUG_MODE_NORMAL_TEXTURE)
		{
			return params.hasNormalTexture ? texture2D(tex_normal, var_texcoord0).rgb : vec3(0.0);
		}
	#endif

		
		if (params.hasNormalTexture)
		{
			lowp vec3 sample_normal = texture2D(tex_normal, var_texcoord0).rgb;
			sample_normal = sample_normal * 2.0 - 1.0;

			/*
			vec3 N = normalize(var_normal);
			vec3 T = normalize(var_tangent); // normalize(q1 * st2.t - q2 * st1.t);
			vec3 B = -normalize(cross(N, T));
			mat3 TBN = var_TBN; // mat3(T, B, N);
			*/
			
			mat3 TBN = var_TBN;
			return normalize(TBN * sample_normal);
		}

		return var_normal;
	}

	vec4 getVertexColor()
	{
		// Maybe we need to check if the model _has_ color attributes? what's the pipeline default?
		return vec4(var_color, 1.0);
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

		materialInfo.baseColor     *= getVertexColor();
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
