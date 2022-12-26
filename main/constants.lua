local M = {}

M.DEBUG_MODE = {
	NONE       = 0,
	BASE_COLOR = 1,
	TC_0       = 2,
	TC_1       = 3,
	ROUGHNESS  = 4,
	METALLIC   = 5,
	NORMALS    = 6,
}

M.LIGHT_TYPE = {
	DIRECTIONAL = 0,
	POINT       = 1,
}

return M