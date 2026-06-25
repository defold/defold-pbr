# Defold PBR Extension Manual

This extension is at an alpha/work-in-progress state. If something does not work, please contact us at:

* [Forum](https://forum.defold.com/)
* [Discord Server](https://discord.gg/6eSFn3U5)

Or open a ticket at the [Github Repository](https://github.com/defold/defold-pbr).

## What This Adds

The base `/defold-pbr` asset library owns the material inputs, BRDF, Defold LightBuffer integration, punctual lights, emissive, occlusion, and final composition. This extension layers image based lighting on top of that base shader stack.

Use Defold directional, point, and spot light components for punctual lights. The extension no longer registers or uploads custom light arrays.

## Integration

1. Add both the base asset library and this extension to your project.
2. Create a game object and attach `/defold-pbr-extension/core.script`.
3. Create environment assets by right-clicking an `.hdr` map and selecting `Defold PBR - Create Environment Assets`.
4. Add the generated environment `.go` file to the collection.
5. Select the active environment from script:

```lua
local PBR = require "defold-pbr-extension/core"

function setup_pbr(self)
    PBR.set_environment("blue_skies")
end
```

6. Assign `/defold-pbr-extension/materials/Defold-PBR.material` to models that should receive IBL.

## Render Script Setup

The extension material needs the generated IBL textures bound while drawing models. Punctual lights and ambient light come from Defold light components and the built-in LightBuffer used by the base `/defold-pbr` shaders.

```lua
local PBR = require "defold-pbr-extension/core"

function update(self)
    -- Set view, projection, depth state, blend state, and predicates as usual.

    PBR.enable_textures()
    render.draw(self.model_pred, { frustum = self.frustum })
    PBR.disable_textures()
end
```

The texture names bound by `PBR.enable_textures()` must match the extension shader uniforms:

```glsl
tex_diffuse_irradiance
tex_prefiltered_reflection
tex_brdflut
```

## Material Inputs

The extension material uses the same glTF material data and sampler names as the base PBR material:

```glsl
PbrMetallicRoughness_baseColorTexture
PbrMetallicRoughness_metallicRoughnessTexture
PbrMaterial_normalTexture
PbrMaterial_occlusionTexture
PbrMaterial_emissiveTexture
```

IBL is injected into the base shader library through `PBRLightData` before final composition:

```glsl
PBRLightData pbr_data = calculate_pbr_light_data(params, material, var_position.xyz);
add_pbr_light_data(pbr_data, calculate_ibl_light_data(params, material));
vec3 color = composite_pbr_light_data(pbr_data);
```

## Generating Environment Lights From HDR Files

The extension contains a built-in editor script that generates engine-ready binaries for prefiltered environment lights. Right-click an `.hdr` file in the project and let the tools generate the required assets.

Note: The first time you run the executables, your OS might block them. Run them outside Defold once and approve them according to your operating system prompts.

Note: Do not open executables or HDR files from Defold. The editor may open them as text and lock up for a long time. Instead, right-click the folder and select `Show in desktop`.

## Exporting Content From GLB Files

The extension also contains an editor script that converts a GLTF file into a Defold collection. Right-click a `.glb` file and select `Extract GLTF Content`.

> [!NOTE]
> This functionality assumes that Python 3 is installed and available as `python`, and that the `dataclasses-json` package is installed.
