import os
import platform
import shutil
import stat
import subprocess
import sys
import urllib.request
import zipfile

import defold_content_helpers
import blender_utils

# Build paths
BUILD_TOOLS_FOLDER           = "build_tools"
DEFOLD_HTTP_BASE             = "https://d.defold.com/archive/stable"
DEFOLD_SHA                   = "9c44c4a9b6cbc9d0cb66b7027b7c984bf364a568"
DEFOLD_BOB_JAR_URL           = "%s/%s/bob/bob.jar" % (DEFOLD_HTTP_BASE, DEFOLD_SHA)
DEFOLD_DMENGINE_URL_TEMPLATE = "%s/%s/engine/x86_64-%s/dmengine%s"
DEFOLD_PREVIEW_PROJECT_URL   = "https://github.com/defold/pbr-viewer/archive/refs/heads/master.zip"

# Scene content paths
TEXTURE_2D_BLANK_PATH   = "/defold-pbr/textures/blank_1x1.png"
TEXTURE_CUBE_BLANK_PATH = "/defold-pbr/textures/blank_cube.cubemap"
VERTEX_PATH             = "/assets/shaders/preview.vp"
FRAGMENT_PATH           = "/assets/shaders/preview.fp"

def get_host_platform_desc():
    # platform, extension
    platforms = {
        "Darwin"  : ("macos", ""),
        "Windows" : ("win32", ".exe"),
        "Linux"   : ("linux", "")
    }
    return platforms[platform.system()]

def get_bob_build_path():
    return "%s/bob.jar" % BUILD_TOOLS_FOLDER
def get_dmengine_platform_path():
    os_name, bin_ext = get_host_platform_desc()
    return "dmengine%s" % (bin_ext)
def get_dmengine_build_path():
    return "%s/%s" % (BUILD_TOOLS_FOLDER, get_dmengine_platform_path())
def get_template_project_path():
    return "%s/pbr-viewer-master" % BUILD_TOOLS_FOLDER

def download_file(path, url):
    if not os.path.exists(path):
        print("Downloading %s" % url)
        urllib.request.urlretrieve(url, path)
    else:
        print("Using cached %s" % path)

def download_and_extract_zip(path, extract_path, url):
    if not os.path.exists(path):
        print("Downloading %s" % url)
        zip_path = path + ".zip"
        urllib.request.urlretrieve(url, zip_path)
        with zipfile.ZipFile(zip_path,"r") as zip_ref:
            zip_ref.extractall(extract_path)
        os.remove(zip_path)
    else:
        print("Using cached %s" % path)

def get_bob():
    download_file(get_bob_build_path(), DEFOLD_BOB_JAR_URL)

def get_dmengine():
    os_name, bin_ext = get_host_platform_desc()
    dmengine_path = get_dmengine_build_path()
    dmengine_http_path = DEFOLD_DMENGINE_URL_TEMPLATE % (DEFOLD_HTTP_BASE, DEFOLD_SHA, os_name, bin_ext)
    download_file(dmengine_path, dmengine_http_path)
    os.chmod(dmengine_path, stat.S_IEXEC)

def get_template_project():
    download_and_extract_zip(get_template_project_path(), BUILD_TOOLS_FOLDER, DEFOLD_PREVIEW_PROJECT_URL)

def copy_into_template_project(src):
    output_dir = "%s/%s" % (get_template_project_path(), os.path.basename(src))
    shutil.rmtree(output_dir)
    shutil.copytree(src, output_dir)

def make_build_tools():
    os.makedirs(BUILD_TOOLS_FOLDER, exist_ok=True)
    get_bob()
    get_dmengine()

def make_project_content():
    subprocess.run(["java", "-jar", "../bob.jar", "resolve", "build"], cwd=get_template_project_path())

def run_dmengine():
    subprocess.run("../%s" % get_dmengine_platform_path(), cwd=get_template_project_path())

def do_preview(gltf_folder):
    print("Previewing project '%s'" % gltf_folder)
    make_build_tools()
    get_template_project()
    copy_into_template_project(gltf_folder)
    make_project_content()
    run_dmengine()

def do_clean():
    try:
        os.remove(BUILD_TOOLS_FOLDER)
    except:
        pass
    print("Finished cleaning build folder %s" % BUILD_TOOLS_FOLDER)
