import os
import sys
import bpy

print("\nDefold Pipeline: FBX To Blender")
print("-------------------------------")

def convert_fbx_to_blend(base_name,fbx):
	if not os.path.isfile(fbx):
		print("ERROR: fbx file %s doesn't exist, aborting." % fbx)
		return

	outpath = os.path.abspath(base_name + ".blend")

	write_prefix = "Converting"

	if os.path.isfile(outpath):
		os.remove(outpath)
		write_prefix = "Replacing"

	print("%s %s to %s" % (write_prefix, fbx, outpath))
	bpy.ops.object.delete()
	bpy.ops.import_scene.fbx(filepath = fbx)
	bpy.ops.wm.save_mainfile(filepath = outpath, check_existing = True)

for x in sys.argv:
	base,ext = os.path.splitext(x)

	if ext == ".fbx":
		convert_fbx_to_blend(base, x)

print("-------------------------------")
