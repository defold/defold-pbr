import bpy
import sys
import os

print("\nDefold Pipeline: Split GLTF")
print("-------------------------------")

def split_gltf(path, outpath):
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath = path)

    os.makedirs(outpath, exist_ok=True)

    for x in bpy.context.scene.objects:
        print(x)
        if not x.type == 'MESH':
            continue
        bpy.ops.object.select_all(action='DESELECT')
        x.select_set(True)
        file_path = os.path.join(outpath, "{}.gltf".format(x.name))
        bpy.ops.export_scene.gltf(filepath         =  file_path,
                                  use_selection    = True,
                                  export_format    = 'GLB',
                                  export_materials = 'NONE',
                                  export_tangents  = True)

gltf_src = sys.argv[-2]
gltf_out = sys.argv[-1]

split_gltf(gltf_src, gltf_out)

print("-------------------------------")
