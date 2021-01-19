#!/bin/bash
## Author: Roger Johnston, Twitter: @VV_X_7
## License: GNU AGPLv3
##
## This script compiles the Nicodemus implant and plugins for the host OS + Windows.
## Ensure you have MinGW installed.
## To cross-compile to a MacOS build target please see the project README.

nimble install -y

nim c --cpu:amd64 -d:release -d:ssl --os:linux --opt:size -o:nicodemus-linux --outdir:./payloads main.nim
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 -d:release -d:ssl --os:linux --opt:size -o:$plugin_name-linux --outdir:./payloads/$plugin_dir $plugin;
done

nim c --cpu:amd64 -d:release -d:ssl --os:macosx --opt:size -o:nicodemus-darwin --outdir:./payloads main.nim
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 -d:release -d:ssl --os:macosx --opt:size -o:$plugin_name-darwin --outdir:./payloads/$plugin_dir $plugin;
done

nim c --cpu:amd64 -d:release -d:ssl --os:windows  --opt:size -d:mingw -o:nicodemus-windows.exe --outdir:./payloads main.nim
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 -d:release -d:ssl --os:windows --opt:size -d:mingw -o:$plugin_name-windows.exe --outdir:./payloads/$plugin_dir $plugin;
done