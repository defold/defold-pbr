# blender-content-pipeline

## Requirements

* Blender
* Python 3.x
* pygltflib

```
Install pygltflib package
python -m pip install pygltflib
```

## Usage

```
python blender_to_defold.py [arguments]
```

Supported arguments:

```
Convert one or more .fbx files to .blend files. These will be stored next to the original file(s)
--fbx-to-blend fbx-file1.fbx fbx-file2.fbx ...

Convert one or more .blend files to .gltf files. These will be stored next to the original file(s)
--blend-to-gltf blend-file1.blend blend-file2.blend ...

Inserts a single .gltf file into a defold project and launches the engine runtime.
--preview-gltf gltf-file.gltf

Cleans the build cache folder
--clean
```

Examples:
```
Converts an .fbx file into gltf and previews it in Defold
python blender_to_defold.py --fbx-to-blend my-scene.fbx --blend-to-gltf my-scene.blend --preview-gltf my-scene.gltf
```