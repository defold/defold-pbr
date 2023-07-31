#!/bin/bash

# Note: It's expected that this script is run from the project root

export PBR_TOOLS_BASE_PATH=https://github.com/Jhonnyg/defold-pbr-utils/releases/latest/download/
export BLENDER_TOOLS_BASE_PATH=https://github.com/defold/blender-content-pipeline/archive/refs/heads/master.zip

export TOOLS_PATH=defold-pbr/tools
export PLUGINS_PATH=defold-pbr/plugins
export OUTPUT_PATH=tools

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-macos --output-dir ${OUTPUT_PATH} -o pbr-utils-macos -L
chmod +x ${OUTPUT_PATH}/pbr-utils-macos

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-linux --output-dir ${OUTPUT_PATH} -o pbr-utils-linux -L
chmod +x ${OUTPUT_PATH}/pbr-utils-linux

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-windows.exe --output-dir ${OUTPUT_PATH} -o pbr-utils-windows.exe -L

# File Sync (FS) + put in root (j)
zip -FSj ${PLUGINS_PATH}/x86_64-macos.zip ${OUTPUT_PATH}/pbr-utils-macos ${OUTPUT_PATH}/osx-python.sh
zip -FSj ${PLUGINS_PATH}/x86_64-win32.zip ${OUTPUT_PATH}/pbr-utils-windows.exe
zip -FSj ${PLUGINS_PATH}/x86_64-linux.zip ${OUTPUT_PATH}/pbr-utils-linux

rm ${OUTPUT_PATH}/pbr-utils-macos
rm ${OUTPUT_PATH}/pbr-utils-windows.exe
rm ${OUTPUT_PATH}/pbr-utils-linux

curl ${BLENDER_TOOLS_BASE_PATH} --output-dir ${OUTPUT_PATH} -o blender-content-pipeline.zip -LJO
unzip ${OUTPUT_PATH}/blender-content-pipeline.zip
rm ${OUTPUT_PATH}/blender-content-pipeline.zip
rm -rf ${TOOLS_PATH}/blender-content-pipeline
mv blender-content-pipeline-master ${TOOLS_PATH}/blender-content-pipeline
