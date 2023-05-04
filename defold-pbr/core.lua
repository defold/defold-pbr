local helpers = require 'defold-pbr/scripts/helpers'

local M = {
	__ctx = nil
}

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

local function light_template(light_type)
	return {
		position  = vmath.vector3(),
		direction = vmath.vector3(),
		color     = vmath.vector3(1, 1, 1),
		intensity = 1,
		type      = light_type,
	}
end

local function extend(a, b)
	for k, v in pairs(b) do
		a[k] = b[k]
	end
	return a
end

local function get_ctx()
	if M.__ctx == nil then
		return error("No PBR context has been created.")
	end
	return M.__ctx
end

M.initialize = function(params)
	if M.__ctx ~= nil then
		return error("Unable to initialize defold-pbr: only a single context allowed.")
	end
	
	local ctx              = {}
	ctx.environment_key    = ""
	ctx.params             = helpers.make_params(params)
	ctx.texture_irradiance = helpers.make_irradiance_texture(ctx.params.irradiance.width, ctx.params.irradiance.height)
	ctx.texture_prefilter  = helpers.make_prefilter_texture(ctx.params.prefilter.width, ctx.params.prefilter.height, ctx.params.prefilter.mipmaps) 
	ctx.texture_brdf_lut   = helpers.make_brdf_lut("/defold-pbr/assets/brdf_lut.bin", 512, 512)
	
	ctx.handle_irradiance  = resource.get_texture_info(ctx.texture_irradiance).handle
	ctx.handle_prefilter   = resource.get_texture_info(ctx.texture_prefilter).handle
	ctx.handle_brdf_lut    = resource.get_texture_info(ctx.texture_brdf_lut).handle
	ctx.render_args        = {
		camera_world   = vmath.vector3(),
		debug_mode     = M.DEBUG_MODE.NONE,
		debug_mode_key = "NONE",
		exposure       = 1,
		lights         = {},
	}

	M.__ctx = ctx
	
	return ctx
end

M.set_environment = function(name, env_params)
	local ctx = get_ctx()
	ctx.environment_key = name
	helpers.load_environment(ctx, env_params)
end

M.get_environment = function()
	return get_ctx().environment_key
end

M.set_debug_mode = function(debug_mode_key)
	local ctx = get_ctx()
	ctx.render_args.debug_mode     = M.DEBUG_MODE[debug_mode_key]
	ctx.render_args.debug_mode_key = debug_mode_key
end

M.get_debug_mode = function()
	return get_ctx().render_args.debug_mode_key
end

M.set_exposure = function(exposure)
	get_ctx().render_args.exposure = exposure
end

M.get_exposure = function()
	return get_ctx().render_args.exposure
end

M.set_light_params = function(light_index, l_params)
	local ctx = get_ctx()
	if ctx.render_args.lights[light_index + 1] == nil then
		return error("Unable to set light parameters, there is no light at index " .. light_index)
	end
	extend(ctx.render_args.lights[light_index+1], l_params)
end

M.get_light_params = function(light_index)
	local ctx = get_ctx()
	if ctx.render_args.lights[light_index + 1] == nil then
		return error("Unable to get light parameters, there is no light at index " .. light_index)
	end
	return ctx.render_args.lights[light_index+1]
end

M.add_light_directional = function(l_params)
	local ctx = get_ctx()
	local l = extend(light_template(helpers.LIGHT_TYPE.DIRECTIONAL), l_params)
	table.insert(ctx.render_args.lights, l)
end

M.add_light_point = function(l_params)
	local ctx = get_ctx()
	local l = extend(light_template(helpers.LIGHT_TYPE.POINT), l_params)
	table.insert(ctx.render_args.lights, l)
end

M.update = function(update_params)
	local ctx = get_ctx()
	extend(ctx.render_args, update_params)
end

M.set_camera_world = function(camera_p)
	local ctx = get_ctx()
	ctx.render_args.camera_world = camera_p
end

------------
-- Rendering
------------

M.get_constants = function()
	local ctx = get_ctx()
	if ctx.render_args.constants == nil then
		ctx.render_args.constants                    = render.constant_buffer()
		ctx.render_args.constants.u_pbr_debug_params = vmath.vector4(ctx.render_args.debug_mode)
		ctx.render_args.constants.u_light_data       = {}
	end

	for k,v in pairs(ctx.render_args.lights) do
		local l_mat = vmath.matrix4()
		l_mat.m00 = v.position.x
		l_mat.m10 = v.position.y
		l_mat.m20 = v.position.z

		l_mat.m01 = v.direction.x
		l_mat.m11 = v.direction.y
		l_mat.m21 = v.direction.z

		l_mat.m02 = v.color.x
		l_mat.m12 = v.color.y
		l_mat.m22 = v.color.z

		l_mat.m03 = v.type
		l_mat.m13 = v.intensity

		ctx.render_args.constants.u_light_data[k] = l_mat
	end

	ctx.render_args.constants.u_pbr_scene_params = vmath.vector4(ctx.render_args.debug_mode, #ctx.render_args.lights, ctx.render_args.exposure, 0)
	ctx.render_args.constants.u_camera_position  = vmath.vector4(ctx.render_args.camera_world.x,ctx.render_args.camera_world.y,ctx.render_args.camera_world.z,0)

	return ctx.render_args.constants
end

M.get_textures = function()
	local ctx = get_ctx()
	return {
		irradiance = ctx.handle_irradiance,
		prefilter  = ctx.handle_prefilter,
		brdf_lut   = ctx.handle_brdf_lut
	}
end

return M
