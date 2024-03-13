# Defold PBR Core Manual

This extension is at an alpha/work-in-progress state! If something doesn't work, please contact us at:

* [Forum](https://forum.defold.com/)
* [Discord Server](https://discord.gg/6eSFn3U5)

Or open a ticket at the [Github Repository](https://github.com/defold/defold-pbr)


### Integrating and initialization

1) To initialize the PBR core, create a new gameobject (or use an existing one) and attach the 'core' script located at /defold-pbr/core.script. This will initialize and create the PBR context.

2) To add an environment light, first create one by right-clicking on a .hdr map and select 'Defold PBR - Create Environment Assets'. This will create a folder next to the .hdr map that contains all the data needed for the PBR lighting. When you have one or more environment maps, add them to the scene by right-clicking somewhere in the scene outline, select 'Add game object file' and then select the environment map .go file.

3) After the core has been initialized, you can start adding lights and environments:

```lua
function setup_pbr(self)
	PBR.set_environment("blue_skies")

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

4) The light calculations in the shader requires that the camera position is updated whenever the camera has moved. To make sure it's always updated, put this somewhere in a script (make sure the ID is correct):
```lua
function update(self)
	PBR.set_camera_world(go.get_world_position("/camera"))
end
```

* Note: This is not done automatically since this extension doesn't deal with any explicit camera or light components, it is up to each project to define what how "light" or "camera" is represented. This done intentionally so that the extension doesn't impose a specific way of working in custom projects.

5) Assign the reference renderer to the game project under bootstrap -> render (or copy it and make your own changes)

(OPTIONAL) If you don't already have a camera setup that renders 3D, you need to do these steps:

6) Create a camera in your collection
7) In one of your script, add these lines:

```lua
function init(self)
	-- note: You need to input the correct camera component id here
	msg.post("my-camera-id", "acquire_camera_focus")
	msg.post("@render:", "use_camera_projection")
	-- ... Other initialization code
end
```

### Integrating in .render_script

* Note: There is a reference render script available in the defold-pbr/render that you can use a start for integration.

The materials and shaders requires the set of support textures and constants to render properly. To setup the drawing of PBR models, first create a custom render script and render prototype (or copy from the builtins folder, or the reference render script available in the PBR extension) if you don't have one already. In the render scripts, you first need to require the PBR core module somewhere (usually the first top lines of the script):

```lua
local PBR = require 'defold-pbr/core'
```

And then in the update function, you need to enable the textures before issuing the .draw command and pass in the constants needed for the rendering:
```lua
function update(self)
	-- do the usual draw setup before drawing, such as clearing buffers etc. The default builtin script takes care of the basic setup here

	-- grab the pbr assets from the PBR core (note, you must have initialized the module first!)
  local pbr_constants = PBR.get_constants()

  -- let the PBR module enable the textures, they must exactly match the uniforms in the shaders to work.
  -- so if you make changes to the shaders, you need to bind the textures manually here instead.
  PBR.enable_textures()

  -- this is the basic draw state setup of rendering models
  render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
  render.enable_state(render.STATE_CULL_FACE)
  render.enable_state(render.STATE_DEPTH_TEST)
  render.set_depth_mask(true)
  render.draw(self.model_pred, { constants = pbr_constants }) -- optionally, pass in a frustum here!

  -- it's not strictly necessary to unbind the textures, but to make sure you don't get side-effect it
  -- is usually a good idea to reset the state after you are done.
  PBR.disable_textures()
end
```

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

