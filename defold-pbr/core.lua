local helpers = require 'defold-pbr/scripts/helpers'

local M = {}

M.initialize = function(params)
	local ctx              = {}
	ctx.params             = helpers.make_params(params)
	ctx.texture_irradiance = helpers.make_irradiance_texture(ctx.params.irradiance.width, ctx.params.irradiance.height)
	ctx.texture_prefilter  = helpers.make_prefilter_texture(ctx.params.prefilter.width, ctx.params.prefilter.height, ctx.params.prefilter.mipmaps) 
	ctx.texture_brdf_lut   = helpers.make_brdf_lut("/defold-pbr/assets/brdf_lut.bin", 512, 512)

	print(ctx.texture_irradiance)
	print(ctx.texture_prefilter)
	print(ctx.texture_brdf_lut)
	
	ctx.handle_irradiance  = resource.get_texture(ctx.texture_irradiance)
	ctx.handle_prefilter   = resource.get_texture(ctx.texture_prefilter)
	ctx.handle_brdf_lut    = resource.get_texture(ctx.texture_brdf_lut)
	ctx.render_args        = {
		lights = {},
	}
	return ctx
end

M.set_environment = function(ctx, env_params)
	helpers.load_environment(ctx, env_params)
end

M.add_light_directional = function(ctx, l_params)
	l_params.type = helpers.LIGHT_TYPE.DIRECTIONAL
	table.insert(ctx.render_args.lights, l_params)
end

M.update = function(ctx, update_params)
	ctx.render_args.brdf_lut           = ctx.handle_brdf_lut
	ctx.render_args.irradiance_texture = ctx.handle_irradiance
	ctx.render_args.prefilter_texture  = ctx.handle_prefilter
	ctx.render_args.camera_world       = update_params.camera_world
	msg.post("@render:", "set_pbr_params", ctx.render_args)
end

return M
