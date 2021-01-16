#!/bin/bash
## Author: Roger Johnston, Twitter: @VV_X_7
## License: GNU AGPLv3
##
## This script compiles the Nicodemus implant and plugins for the host OS + Windows.
## Ensure you have MinGW installed.
## To cross-compile to a MacOS build target please see the project README.
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux amd64
    nim c --cpu:amd64 -d:release -d:ssl --opt:size -o:nicodemus-linux-amd64 --outdir:./payloads main.nim
    # Compile Linux plugins.
    for plugin in $(find module/plugin/ -name "*.nim"); do
        plugin_name=$(basename -s .nim $plugin)
        plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
        nim c --cpu:amd64 -d:release -d:ssl --opt:size -o:$plugin_name-linux-amd64 --outdir:./payloads/$plugin_dir $plugin;
    done
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS amd64
    nim c --cpu:amd64 -d:release -d:ssl --opt:size -o:nicodemus-darwin-amd64 --outdir:./payloads main.nim
    # Compile MacOS plugins.
    for plugin in $(find module/plugin/ -name "*.nim"); do
        plugin_name=$(basename -s .nim $plugin)
        plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
        nim c --cpu:amd64 -d:release -d:ssl --opt:size -o:$plugin_name-darwin-amd64 --outdir:./payloads/$plugin_dir $plugin;
    done
fi

# Windows amd64
nim c --cpu:amd64 -d:release -d:ssl --opt:size -d:mingw -o:nicodemus-windows-amd64 --outdir:./payloads main.nim
# Compile Windows plugins.
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 -d:release -d:ssl --opt:size -d:mingw -o:$plugin_name-windows-amd64 --outdir:./payloads/$plugin_dir $plugin;
done