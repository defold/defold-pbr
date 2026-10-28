# Defold PBR Extension Manual

This extension is at an alpha/work-in-progress state. If something does not work, please contact us at:

* [Forum](https://forum.defold.com/)
* [Discord Server](https://discord.gg/6eSFn3U5)

Or open a ticket at the [Github Repository](https://github.com/defold/defold-pbr).

## Minimum Defold version

Requires **Defold 1.14.1 or later**.

## What This Adds

The engine's `/builtins/materials/gltf.*` shaders provide material inputs, BRDF, Defold LightBuffer integration, punctual lights, emissive, occlusion, and final composition. This extension replaces the built-in constant ambient contribution with diffuse irradiance and prefiltered specular reflections from an HDR environment, using a BRDF LUT.

Use Defold directional, point, and spot light components for punctual lights. The extension does not register or upload custom light arrays. The separate `asset-pbr` dependency is no longer required. For basic PBR without IBL, use the engine's built-in materials directly.

## Integration

1. Add this extension to your project dependencies and fetch libraries. Do not add `asset-pbr` for this extension.
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

The extension material needs the generated IBL textures bound while drawing models. Punctual lights come from Defold light components and the built-in LightBuffer. Indirect lighting comes from the bound environment textures.

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

The extension material uses `/builtins/materials/gltf.vp`, the built-in glTF material data, and the same sampler names as `/builtins/materials/gltf.material`:

```glsl
PbrMetallicRoughness_baseColorTexture
PbrMetallicRoughness_metallicRoughnessTexture
PbrMaterial_normalTexture
PbrMaterial_occlusionTexture
PbrMaterial_emissiveTexture
```

IBL is assigned to `PBRLighting.indirect` before the built-in composition step:

```glsl
PBRMaterial inputs = pbr_sample_material(var_texcoord0, var_color);
PBRSurface surface = pbr_sample_surface(inputs, var_texcoord0);
MaterialInfo material = pbr_create_material_info(inputs);
PBRLighting lighting = pbr_create_lighting();
if (!inputs.unlit)
{
    lighting.direct = pbr_evaluate_direct_lighting(material, surface, var_view);
    lighting.indirect = calculate_ibl_light_data(surface, material);
}
vec3 color = pbr_compose_lighting(inputs, lighting, inputs.occlusion, inputs.occlusion);
```

The full fragment shader also applies the built-in sidedness and alpha-cutoff checks, preserves the material's alpha mode, applies exposure, and converts the composed linear color to sRGB. Material occlusion affects indirect lighting; unlit materials skip both punctual lighting and IBL.

## Upgrading From The asset-pbr-Based Version

Update the extension and remove the `asset-pbr` dependency if nothing else in your project uses it, then run **Project > Fetch Libraries**. The extension material path, generated environment assets, texture bindings, and Lua API stay the same.

Custom shaders must replace `/defold-pbr/shaders/*` includes with the engine's glTF shader modules. Material sampling now uses `PBRMaterial`, geometry uses `PBRSurface`, and direct/indirect light contributions use `PBRLighting` and `PBRLightContribution`. See `/defold-pbr-extension/shaders/pbr.fp` and `pbr_ibl.glsl` for the complete integration.

## Generating Environment Lights From HDR Files

The extension contains a built-in editor script that generates engine-ready binaries for prefiltered environment lights. Right-click an `.hdr` file in the project and let the tools generate the required assets.

Note: The first time you run the executables, your OS might block them. Run them outside Defold once and approve them according to your operating system prompts.

Note: Do not open executables or HDR files from Defold. The editor may open them as text and lock up for a long time. Instead, right-click the folder and select `Show in desktop`.

## Importing glTF And GLB Models

Use Defold 1.14.1's native glTF/GLB importer. Expand the file in the Assets view to inspect its meshes, materials, and images, then assign the file or one of its meshes to a Model component. Let the editor populate the glTF material and texture bindings, and assign `/defold-pbr-extension/materials/Defold-PBR.material` to the models that should receive IBL.

The old `Defold PBR - Extract GLTF content` command is no longer registered. Its bundled Blender converter generates materials for the old shader API; the native importer replaces that workflow and does not require Python or Blender. Existing generated environment assets are unrelated to this change and can still be used.
