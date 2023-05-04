#!/bin/bash

# Note: It's expected that this script is run from the project root
export TOOLS_PATH=defold-pbr/tools
export PLATFORM_EXT=""

if [ "$(uname)" == "Darwin" ]; then
    export PLATFORM="macos"
    export BINARY_NAME=pbr-utils-macos
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    export PLATFORM="windows"
    export PLATFORM_EXT=".exe"
    export BINARY_NAME=pbr-utils-macos.exe
else
    export PLATFORM="linux"
fi

export OUTPUT_FILE_PATH=${TOOLS_PATH}/${BINARY_NAME}

if [ "" == "${DEFOLD_PBR}" ]; then
    echo "DEFOLD_PBR is not set."
else
	echo "Copying.. ${DEFOLD_PBR}/build/pbr-utils${PLATFORM_EXT} to ${OUTPUT_FILE_PATH}"
	cp ${DEFOLD_PBR}/build/pbr-utils${PLATFORM_EXT} ${OUTPUT_FILE_PATH}
	if [ "$PLATFORM" != "windows" ]; then
		chmod +x ${OUTPUT_FILE_PATH}
	fi
fi

