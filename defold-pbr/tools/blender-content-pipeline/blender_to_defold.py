#!/usr/bin/env python
import argparse
import platform
import os
import subprocess
import sys
import blender_utils

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Convert blender content to Defold')
	parser.add_argument('--fbx-to-blend',   nargs='+')
	parser.add_argument('--verify-blend',   nargs='+')
	parser.add_argument('--blend-to-gltf',  nargs='+')
	parser.add_argument('--gltf-to-defold', nargs=1)
	parser.add_argument('--preview-gltf',   nargs=1)
	parser.add_argument('--relative-path',  nargs=1)
	parser.add_argument('--clean',          action='store_true')

	args = parser.parse_args()
	if args.fbx_to_blend:
		print("Converting .fbx files to Blender")
		blender_utils.run_blender_script("convert_fbx_to_blender.py", args.fbx_to_blend)
	if args.blend_to_gltf:
		print("Converting .blend files to GLTF")
		blender_utils.run_blender_script("convert_blend_to_gltf.py", args.blend_to_gltf)
	if args.preview_gltf:
		print("Previewing .gltf in Defold")
		import preview_gltf
		preview_gltf.do_preview(args.preview_gltf[0])
	if args.gltf_to_defold:
		print("Building Defold project from gltf")
		import convert_gltf_to_defold
		relative_path = args.relative_path and args.relative_path[0] or None
		convert_gltf_to_defold.do_build_project(args.gltf_to_defold, relative_path)
	if args.clean:
		print("Cleaning build folder")
		import preview_gltf
		preview_gltf.do_clean()

	if not any(vars(args).values()):
		parser.print_help(sys.stderr)
