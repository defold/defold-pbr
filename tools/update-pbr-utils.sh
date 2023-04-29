#!/bin/bash

# Note: It's expected that this script is run from the project root

export DOWNLOAD_BASE=https://github.com/Jhonnyg/defold-pbr-utils/releases/latest/download/
export TOOLS_PATH=defold-pbr/tools
export OUTPUT_PATH=tools

curl ${DOWNLOAD_BASE}/pbr-utils-macos --output-dir ${OUTPUT_PATH} -o pbr-utils-macos -L
chmod +x ${OUTPUT_PATH}/pbr-utils-macos

curl ${DOWNLOAD_BASE}/pbr-utils-windows.exe --output-dir ${OUTPUT_PATH} -o pbr-utils-windows.exe -L

mv ${OUTPUT_PATH}/pbr-utils-macos ${TOOLS_PATH}
mv ${OUTPUT_PATH}/pbr-utils-windows.exe ${TOOLS_PATH}

