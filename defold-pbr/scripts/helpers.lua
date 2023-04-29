
local M = {}

M.LIGHT_TYPE = {
	DIRECTIONAL = 0,
	POINT       = 1,
}

M.make_irradiance_texture = function(w, h)
	local targs = {
		type   = resource.TEXTURE_TYPE_CUBE_MAP,
		width  = w,
		height = h,
		format = resource.TEXTURE_FORMAT_RGBA32F
	}
	return resource.create_texture("/defold-pbr/irradiance.texturec", targs)
end

M.make_prefilter_texture = function(w, h, mipmaps)
	local targs = {
		type        = resource.TEXTURE_TYPE_CUBE_MAP,
		width       = w,
		height      = h,
		format      = resource.TEXTURE_FORMAT_RGBA32F,
		max_mipmaps = mipmaps
	}
	return resource.create_texture("/defold-pbr/prefilter.texturec", targs)
end

M.make_brdf_lut = function(path, w, h)
	local targs = {
		type   = resource.TEXTURE_TYPE_2D,
		width  = w,
		height = h,
		format = resource.TEXTURE_FORMAT_RGBA32F
	}

	local tex_path = resource.create_texture("/pbr-brdf-lut.texturec", targs)
	local data     = resource.load(path)
	resource.set_texture(tex_path, targs, data)
	return tex_path
end

M.load_environment = function(ctx, env)
	resource.set_texture(ctx.texture_irradiance, {
		type   = resource.TEXTURE_TYPE_CUBE_MAP,
		width  = ctx.params.irradiance.width,
		height = ctx.params.irradiance.height,
		format = resource.TEXTURE_FORMAT_RGBA32F
	}, resource.load(env.path .. "/irradiance.bin"))

	local slice_width  = ctx.params.prefilter.width
	local slice_height = ctx.params.prefilter.height
	local mipmaps      = ctx.params.prefilter.mipmaps

	for i = 0, mipmaps-1 do
		local slice_path = env.path .. "/prefilter" .. "_mm_" .. i .. ".bin"
		resource.set_texture(ctx.texture_prefilter, {
			type        = resource.TEXTURE_TYPE_CUBE_MAP,
			width       = slice_width,
			height      = slice_height,
			format      = resource.TEXTURE_FORMAT_RGBA32F,
			mipmap      = i,
		}, resource.load(slice_path))
		slice_width  = slice_height / 2
		slice_height = slice_height / 2
	end

	ctx.handle_irradiance = resource.get_texture_info(ctx.texture_irradiance).handle
	ctx.handle_prefilter  = resource.get_texture_info(ctx.texture_prefilter).handle
end

M.make_params = function(from_params)
	
	local p = {
		irradiance = {
			width  = 64,
			height = 64
		},
		prefilter = {
			width   = 256,
			height  = 256,
			mipmaps = 9
		}
	}

	if from_params == nil then
		return p
	end

	p.irradiance = from_params.irradiance or p.irradiance
	p.prefilter  = from_params.prefilter or p.prefilter
	return p
end

return M