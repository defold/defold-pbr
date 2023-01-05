local M = {}

M.DEBUG_MODE = {
	NONE           = 0,
	BASE_COLOR     = 1,
	TC_0           = 2,
	TC_1           = 3,
	ROUGHNESS      = 4,
	METALLIC       = 5,
	NORMAL_TEXTURE = 6,
	NORMALS        = 7,
	TANGENTS       = 8,
	BITANGENTS     = 9,
	OCCLUSION      = 10,
}

M.LIGHT_TYPE = {
	DIRECTIONAL = 0,
	POINT       = 1,
}

M.ENVIRONMENTS = {
	{
		name = "Newport Loft",
		path = "/defold-pbr/assets/env_newport_loft"
	},
	{
		name = "Limpopo Golf",
		path = "/defold-pbr/assets/env_limpopo_golf"
	},
	{
		name = "Reinforced Concrete",
		path = "/defold-pbr/assets/env_reinforced_concrete"
	}
}

return M