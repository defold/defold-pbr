local helpers = require 'defold-pbr/scripts/helpers'

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

local M = {}

M.initialize = function(params)
	local ctx              = {}
	ctx.params             = helpers.make_params(params)
	ctx.texture_irradiance = helpers.make_irradiance_texture(ctx.params.irradiance.width, ctx.params.irradiance.height)
	ctx.texture_prefilter  = helpers.make_prefilter_texture(ctx.params.prefilter.width, ctx.params.prefilter.height, ctx.params.prefilter.mipmaps) 
	ctx.texture_brdf_lut   = helpers.make_brdf_lut("/defold-pbr/assets/brdf_lut.bin", 512, 512)
	
	ctx.handle_irradiance  = resource.get_texture_info(ctx.texture_irradiance).handle
	ctx.handle_prefilter   = resource.get_texture_info(ctx.texture_prefilter).handle
	ctx.handle_brdf_lut    = resource.get_texture_info(ctx.texture_brdf_lut).handle
	ctx.render_args        = {
		lights = {},
	}
	
	return ctx
end

M.set_environment = function(ctx, env_params)
	helpers.load_environment(ctx, env_params)
end

M.add_light_directional = function(ctx, l_params)
	local l = extend(light_template(helpers.LIGHT_TYPE.DIRECTIONAL), l_params)
	table.insert(ctx.render_args.lights, l)
	msg.post("@render:", "add_light", l)
end

M.add_light_point = function(ctx, l_params)
	local l = extend(light_template(helpers.LIGHT_TYPE.POINT), l_params)
	table.insert(ctx.render_args.lights, l)
	msg.post("@render:", "add_light", l)
end

M.update = function(ctx, update_params)
	ctx.render_args.brdf_lut           = ctx.handle_brdf_lut
	ctx.render_args.irradiance_texture = ctx.handle_irradiance
	ctx.render_args.prefilter_texture  = ctx.handle_prefilter
	ctx.render_args.camera_world       = update_params.camera_world
	ctx.render_args.exposure           = update_params.exposure
	msg.post("@render:", "set_pbr_params", ctx.render_args)
end

return M
