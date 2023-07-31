import platform
import os
import subprocess

def get_blender_bin():
	host_platform = platform.system()
	if host_platform == "Darwin":
		return "/Applications/Blender.app/Contents/MacOS/Blender"
	else:
		print("Unable to find blender installation")
		os.exit(-1)

def run_blender_script(path, args):
	blender_bin = get_blender_bin()
	subprocess.run([blender_bin, '-b', '-P', path, "--"] + args)
