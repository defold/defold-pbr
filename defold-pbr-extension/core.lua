local helpers = require "defold-pbr-extension/scripts/helpers"

local M = {
	__ctx = nil
}

M.MESSAGES = {
	LOAD_ENVIRONMENT = hash("PBR_MSG_LOAD_ENVIRONMENT")
}

local function get_ctx()
	if M.__ctx == nil then
		return error("No PBR extension context has been created.")
	end
	return M.__ctx
end

M.initialize = function(brdf_lut_buffer, params)
	if M.__ctx ~= nil then
		return error("Unable to initialize defold-pbr-extension: only a single context allowed.")
	end

	local ctx = {}
	ctx.environment_key = nil
	ctx.environments = {}
	ctx.params = helpers.make_params(params)
	ctx.texture_irradiance = helpers.make_irradiance_texture(ctx.params.irradiance.width, ctx.params.irradiance.height)
	ctx.texture_prefilter = helpers.make_prefilter_texture(ctx.params.prefilter.width, ctx.params.prefilter.height, ctx.params.prefilter.mipmaps)
	ctx.texture_brdf_lut = helpers.make_brdf_lut(brdf_lut_buffer, 512, 512)

	ctx.handle_irradiance = resource.get_texture_info(ctx.texture_irradiance).handle
	ctx.handle_prefilter = resource.get_texture_info(ctx.texture_prefilter).handle
	ctx.handle_brdf_lut = resource.get_texture_info(ctx.texture_brdf_lut).handle

	M.__ctx = ctx

	return ctx
end

M.context = get_ctx

M.environments = {}

M.add_environment = function(name, env_go)
	M.environments[name] = env_go
end

M.set_environment = function(name)
	local ctx = get_ctx()
	ctx.environment_key = name
	msg.post(M.environments[name], M.MESSAGES.LOAD_ENVIRONMENT)
end

M.get_environment = function()
	return get_ctx().environment_key
end

M.get_environments = function()
	return M.environments
end

M.get_textures = function()
	local ctx = get_ctx()
	return {
		irradiance = ctx.handle_irradiance,
		prefilter = ctx.handle_prefilter,
		brdf_lut = ctx.handle_brdf_lut
	}
end

M.enable_textures = function()
	local ctx = get_ctx()
	render.enable_texture("tex_diffuse_irradiance", ctx.handle_irradiance)
	render.enable_texture("tex_prefiltered_reflection", ctx.handle_prefilter)
	render.enable_texture("tex_brdflut", ctx.handle_brdf_lut)
end

M.disable_textures = function()
	render.disable_texture("tex_diffuse_irradiance")
	render.disable_texture("tex_prefiltered_reflection")
	render.disable_texture("tex_brdflut")
end

return M
