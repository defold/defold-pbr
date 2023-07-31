#!/bin/bash

# Note: It's expected that this script is run from the project root

export PBR_TOOLS_BASE_PATH=https://github.com/Jhonnyg/defold-pbr-utils/releases/latest/download/
export BLENDER_TOOLS_BASE_PATH=https://github.com/defold/blender-content-pipeline/archive/refs/heads/master.zip

export TOOLS_PATH=defold-pbr/tools
export OUTPUT_PATH=tools

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-macos --output-dir ${OUTPUT_PATH} -o pbr-utils-macos -L
chmod +x ${OUTPUT_PATH}/pbr-utils-macos

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-linux --output-dir ${OUTPUT_PATH} -o pbr-utils-linux -L
chmod +x ${OUTPUT_PATH}/pbr-utils-linux

curl ${PBR_TOOLS_BASE_PATH}/pbr-utils-windows.exe --output-dir ${OUTPUT_PATH} -o pbr-utils-windows.exe -L

curl ${BLENDER_TOOLS_BASE_PATH} --output-dir ${OUTPUT_PATH} -o blender-content-pipeline.zip -LJO
unzip ${OUTPUT_PATH}/blender-content-pipeline.zip
rm ${OUTPUT_PATH}/blender-content-pipeline.zip
rm -rf ${TOOLS_PATH}/blender-content-pipeline

mv ${OUTPUT_PATH}/pbr-utils-macos ${TOOLS_PATH}
mv ${OUTPUT_PATH}/pbr-utils-windows.exe ${TOOLS_PATH}
mv ${OUTPUT_PATH}/pbr-utils-linux ${TOOLS_PATH}
mv blender-content-pipeline-master ${TOOLS_PATH}/blender-content-pipeline
