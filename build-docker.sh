#!/bin/bash
## Author: Roger Johnston, Twitter: @VV_X_7
## License: GNU AGPLv3
##
## Auto-build script using the docker chrishellerappsian/docker-nim-cross

nimble install -y

# Linux amd64
nim c --cpu:amd64 --os:linux -d:release -d:ssl --opt:size -o:nicodemus-linux --outdir:./payloads main.nim
# Compile Linux plugins.
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 --os:linux -d:release -d:ssl --opt:size -o:$plugin_name-linux --outdir:./payloads/$plugin_dir $plugin;
done

# MacOS amd64
nim c --cpu:amd64 --os:macosx -d:release -d:ssl --opt:size -o:nicodemus-darwin --outdir:./payloads main.nim
# Compile MacOS plugins.
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 --os:macosx -d:release -d:ssl --opt:size -o:$plugin_name-darwin --outdir:./payloads/$plugin_dir $plugin;
done

# Windows amd64
nim c --cpu:amd64 --os:windows -d:release -d:ssl --opt:size -d:mingw -o:nicodemus-windows.exe --outdir:./payloads main.nim
# Compile Windows plugins.
for plugin in $(find module/plugin/ -name "*.nim"); do
    plugin_name=$(basename -s .nim $plugin)
    plugin_dir=$(dirname $plugin| cut -d '/' -f2-)
    nim c --cpu:amd64 --os:windows -d:release -d:ssl --opt:size -d:mingw -o:$plugin_name-windows.exe --outdir:./payloads/$plugin_dir $plugin;
done
