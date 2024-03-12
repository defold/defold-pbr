#!/bin/bash

# Note: It's expected that this script is run from the project root

export PBR_TOOLS_BASE_PATH=https://github.com/Jhonnyg/defold-pbr-utils/releases/latest/download/
export BLENDER_TOOLS_BASE_PATH=https://github.com/defold/blender-content-pipeline/archive/refs/heads/master.zip

export TOOLS_PATH=defold-pbr/tools
export PLUGINS_PATH=defold-pbr/plugins
export OUTPUT_PATH=tools

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-arm64-macos --output-dir ${OUTPUT_PATH} -o pbr-utils-arm64-macos -L
chmod +x ${OUTPUT_PATH}/pbr-utils-arm64-macos

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-x86_64-macos --output-dir ${OUTPUT_PATH} -o pbr-utils-x86_64-macos -L
chmod +x ${OUTPUT_PATH}/pbr-utils-x86_64-macos

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-linux --output-dir ${OUTPUT_PATH} -o pbr-utils-linux -L
chmod +x ${OUTPUT_PATH}/pbr-utils-linux

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-windows.exe --output-dir ${OUTPUT_PATH} -o pbr-utils-windows.exe -L

# File Sync (FS) + put in root (j)
zip -FSj ${PLUGINS_PATH}/arm64-macos.zip  ${OUTPUT_PATH}/pbr-utils-arm64-macos ${OUTPUT_PATH}/osx-python.sh
zip -FSj ${PLUGINS_PATH}/x86_64-macos.zip ${OUTPUT_PATH}/pbr-utils-x86_64-macos ${OUTPUT_PATH}/osx-python.sh
zip -FSj ${PLUGINS_PATH}/x86_64-win32.zip ${OUTPUT_PATH}/pbr-utils-windows.exe
zip -FSj ${PLUGINS_PATH}/x86_64-linux.zip ${OUTPUT_PATH}/pbr-utils-linux

rm ${OUTPUT_PATH}/pbr-utils-*

curl ${BLENDER_TOOLS_BASE_PATH} --output-dir ${OUTPUT_PATH} -o blender-content-pipeline.zip -LJO
mv ${OUTPUT_PATH}/blender-content-pipeline.zip ${PLUGINS_PATH}/common.zip
