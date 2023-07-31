import os
import sys
import bpy

print("\nDefold Pipeline: Blender To GLTF")
print("-------------------------------")

def convert_blend_to_gltf(base_name, blend):
    if not os.path.isfile(blend):
        print("ERROR: .blend file %s doesn't exist, aborting." % blend)
        return

    outpath = os.path.abspath(base_name + ".gltf")

    write_prefix = "Converting"
    if os.path.isfile(outpath):
        os.remove(outpath)
        write_prefix = "Replacing"

    print("%s %s to %s" % (write_prefix, blend, outpath))

    bpy.ops.object.delete()
    bpy.ops.wm.open_mainfile(filepath = blend)
    bpy.ops.mesh.separate(type='MATERIAL')
    bpy.ops.export_scene.gltf(filepath = outpath)

for x in sys.argv:
    base,ext = os.path.splitext(x)
    if ext == ".blend":
        convert_blend_to_gltf(base, x)

print("-------------------------------")
