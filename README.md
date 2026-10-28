# Defold PBR Extension

Live demo: http://defold.com/defold-pbr/

Image based lighting (IBL) for Defold's built-in glTF PBR shaders. This extension adds HDR environment processing tools, diffuse irradiance, prefiltered environment reflections, a BRDF LUT, and an IBL-enabled material.

## Defold 1.14.1 and later

This version requires **Defold 1.14.1 or later**. It uses the engine's `/builtins/materials/gltf.*`.

For basic glTF PBR rendering with directional, point, and spot lights, use Defold's built-in materials.

this extension is only needed when you want its IBL features. The built-in fragment shader provides a constant ambient contribution, which this extension replaces with lighting sampled from an environment map.

## Updating older projects

When upgrading an existing project, update this extension, remove the `asset-pbr` dependency if no other code uses it, and run **Project > Fetch Libraries**. Existing generated environment assets and the `defold-pbr-extension/core` Lua API can still be used. Custom shaders using the old `PBRParams` / `PBRLightData` API need to migrate to the built-in `PBRMaterial`, `PBRSurface`, and `PBRLighting` API.

Import glTF/GLB models with the editor's native importer and assign the extension material for IBL. The legacy Blender-based `Extract GLTF content` command has been retired because it generates materials for the old shader API.

Please read [the extension manual](defold-pbr-extension/README.md) for integration details.

## Issues reporting

Please open a ticket at the [Github Repository](https://github.com/defold/defold-pbr).
Problems or questions? Please contact us at our [Forum](https://forum.defold.com/) or our [Discord Server](https://discord.gg/6eSFn3U5).

## Credits

* Shaders based on the [GLTF sample viewer](https://github.com/KhronosGroup/glTF-Sample-Viewer)
* Example GLTF content downloaded from [GLTF sample models](https://github.com/KhronosGroup/glTF-Sample-Models)
* Environment maps downloaded from [Polyhaven](https://polyhaven.com)
