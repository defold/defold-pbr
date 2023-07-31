# Defold PBR Core Manual

This extension is at an alpha/work-in-progress state! If something doesn't work, please contact us at:

* [Forum](https://forum.defold.com/)
* [Discord Server](https://discord.gg/6eSFn3U5)

Or open a ticket at the [Github Repository](https://github.com/Jhonnyg/defold-pbr)


### Integrating in .script / gameobject world

1) First, add "defold-pbr/assets" to project -> custom resources in your game.project file. This is needed for the PBR-core to find support assets needed during rendering.

2) To initialize the PBR core, add the following in a .script or lua module somewhere in the project:

```lua
local PBR = require 'defold-pbr/core'

function init(self)
	-- Initialize the PBR ctx
	PBR.initialize()
end
```

3) After this step, you can start adding lights and environments:

```lua
function setup_pbr(self)
	-- pbr is initialized at this point
	PBR.set_environment("blue_skies", require("path/to/environment-map/meta"))
	PBR.add_environment_light({
		direction = vmath.vector3(-1, -1, -1),
		color     = vmath.vector3(0.5, 0.5, 1),
		intensity = 1
	})
	PBR.add_point_light({
		position  = vmath.vector3(0, 1, 0),
		color     = vmath.vector3(1, 0, 0),
		intensity = 0.5
	})
end
```

4) For the environments to load, you need to add the path to where to find them under project -> custom resources!

5) The light calculations in the shader requires that the camera position is updated whenever the camera has moved.
```lua
function update(self)
	PBR.set_camera_world(go.get_world_position("/camera"))
end
```

* Note: This is not done automatically since this extension doesn't deal with any explicit camera or light components, it is up to each project to define what how "light" or "camera" is represented. This done intentionally so that the extension doesn't impose a specific way of working in custom projects.

6) (OPTIONAL) Assign the reference renderer to the game project under bootstrap -> render


### Integrating in .render_script

* Note: There is a reference render script available in the defold-pbr/render that you can use a start for integration.

The materials and shaders requires the set of support textures and constants to render properly. To setup the drawing of PBR models, first create a custom render script and render prototype (or copy from the builtins folder) if you don't have one already. In the render scripts, you first need to require the PBR core module somewhere (usually the first top lines of the script):

```lua
local PBR = require 'defold-pbr/core'
```

And then in the update function, you need to grab the support textures from the PBR module and enable them onto the render state:
```lua
function update(self)
	-- do the usual draw setup before drawing, such as clearing buffers etc. The default builtin script takes care of the basic setup here

	-- grab the pbr assets from the PBR core (note, you must have initialized the module first!)
  local pbr_constants = PBR.get_constants()
  local pbr_textures  = PBR.get_textures()

  -- render the models
  render.enable_texture(0, pbr_textures.irradiance)
  render.enable_texture(1, pbr_textures.prefilter)
  render.enable_texture(2, pbr_textures.brdf_lut)

  -- this is the basic draw state setup of rendering models
  render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
  render.enable_state(render.STATE_CULL_FACE)
  render.enable_state(render.STATE_DEPTH_TEST)
  render.set_depth_mask(true)
  render.draw(self.model_pred, { constants = pbr_constants }) -- optionally, pass in a frustum here!

  render.disable_texture(0)
  render.disable_texture(1)
  render.disable_texture(2)
end
```

Note: The default base material uses the "model" predicate, so make sure to create such a predicate first somewhere in your render scripts init function!


### Generating environment lights from .hdr files

The extension contains a built-in editor script that can be used to generate the engine ready binaries for the prefiltered environment lights.
To use the extension, right-click on a .hdr file somewhere in the project and the tools should do the rest!

Note: The first time you run the executables, your OS might not accept running them and the script won't be able to run them. Before you can run them, you must run them outside of Defold ONCE. This step is dependant on what OS you use, but there is usually a popup with instructions how to accept executables from "untrusted sources". Furthermore, this step is only necessary the first time you run the tools (or when the tools have been updated). It is an annoying process, but currently it's the only way.

Note: DON'T OPEN EXECUTABLES OR HDR FILES FROM DEFOLD. The editor will open them as a text file, which will lock your editor for a very long time. Instead, right click the folder and select "Show in desktop" - this will open the folder in your OS and you can open them from there.

### Exporting content from .glb files into Defold collections

The extension also contains an editor script that converts a GLTF file into a Defold collection that can be used as a complete scene, or parts that can be copied into other collections to combine various scenes. To use this functionality, rick-click on a .glb file and select the "Extract GLTF Content" option in the drop-down. Note that this option will only be available for .glb files specifically.

### Material specification

If you use the default setup, the PBR shaders require material data to be exported and represented in a specific way. The GLTF conversion scripts do this data generation automatically, but if you want to do something more custom like changing parameters in runtime, this is how the material data is represented currently:

For each material that is exported, three constants are used:

```glsl
u_pbr_params_0.xyzw : Base color
u_pbr_params_1.x    : Metallic value
u_pbr_params_1.y    : Roughness value
u_pbr_params_1.z    : Material uses albedo texture if > 0, otherwise uses base color
u_pbr_params_1.w    : Material uses normal texture if > 0, otherwise uses geometry normal
u_pbr_params_2.x    : Material uses emissive texture if > 0
u_pbr_params_2.y    : Material uses metallic / roughness texture if > 0, otherwise uses metallic or roughness values
u_pbr_params_2.z    : Material uses occlussion texture if > 0
u_pbr_params_2.w    : Unused (0)
```

Global data, set by a constant buffer in the core.lua module:

```glsl
u_pbr_scene_params.x : Debug rendering mode
u_pbr_scene_params.y : Light count
u_pbr_scene_params.z : Camera exposure
u_pbr_scene_params.w : Unused (0)
```

