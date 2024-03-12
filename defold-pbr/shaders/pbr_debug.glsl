#ifndef PBR_DEBUG
#define PBR_DEBUG

	#define DEBUG_MODE_NONE           0
	#define DEBUG_MODE_BASE_COLOR     1
	#define DEBUG_MODE_TC_0           2
	#define DEBUG_MODE_TC_1           3
	#define DEBUG_MODE_ROUGHNESS      4
	#define DEBUG_MODE_METALLIC       5
	#define DEBUG_MODE_NORMAL_TEXTURE 6
	#define DEBUG_MODE_NORMALS        7
	#define DEBUG_MODE_TANGENTS       8
	#define DEBUG_MODE_BITANGENTS     9
	#define DEBUG_MODE_OCCLUSION      10
	#define DEBUG_MODE_DIFFUSE        11
	#define DEBUG_MODE_SPECULAR       12

	#include "/defold-pbr/shaders/pbr_input.glsl"
	#include "/defold-pbr/shaders/pbr_lighting.glsl"

	#define PBR_DEBUG_MODE int(u_pbr_scene_params.x)

	#ifdef USE_DEBUG_DRAWING
		vec4 applyDebugMode(vec4 color_in, MaterialInfo materialInfo, LightingInfo lightInfo, PBRData pbrData)
		{
			if      (PBR_DEBUG_MODE == DEBUG_MODE_NONE)           return color_in;
			else if (PBR_DEBUG_MODE == DEBUG_MODE_BASE_COLOR)     return vec4(fromLinear(materialInfo.baseColor.rgb), materialInfo.baseColor.a);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_TC_0)           return vec4(mod(var_texcoord0, 1.0), 0.0, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_TC_1)           return vec4(mod(var_texcoord1, 1.0), 0.0, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_ROUGHNESS)      return vec4(vec3(materialInfo.perceptualRoughness), 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_METALLIC)       return vec4(vec3(materialInfo.metallic), 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_NORMALS)        return vec4((pbrData.vertexNormal + 1.0) * 0.5, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_NORMAL_TEXTURE) return vec4(pbrData.vertexNormal, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_TANGENTS)       return vec4((pbrData.vertexNormal + 1.0) * 0.5, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_BITANGENTS)     return vec4((pbrData.vertexNormal + 1.0) * 0.5, 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_OCCLUSION)      return vec4(vec3(lightInfo.occlusion), 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_DIFFUSE)        return vec4(vec3(exposure(lightInfo.diffuse, PBR_CAMERA_EXPOSURE)), 1.0);
			else if (PBR_DEBUG_MODE == DEBUG_MODE_SPECULAR)       return vec4(vec3(exposure(lightInfo.specular, PBR_CAMERA_EXPOSURE)), 1.0);
			return color_in;
		}
	#else
		#define applyDebugMode(color_in, materialInfo, lightInfo, pbrData) (color_in)
	#endif

#endif // PBR_DEBUG