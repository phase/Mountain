#!/usr/bin/env bash

git submodule update --init
dir=$(pwd -P)
mkdir -p $dir/minecraft/bin/

echo "Getting variables from BuildData/info.json..."
minecraftVersion="$(cat BuildData/info.json | grep minecraftVersion | cut -d '"' -f 4)"
accessTransforms="BuildData/mappings/"$(cat BuildData/info.json | grep accessTransforms | cut -d '"' -f 4)
classMappings="BuildData/mappings/"$(cat BuildData/info.json | grep classMappings | cut -d '"' -f 4)
memberMappings="BuildData/mappings/"$(cat BuildData/info.json | grep memberMappings | cut -d '"' -f 4)
packageMappings="BuildData/mappings/"$(cat BuildData/info.json | grep packageMappings | cut -d '"' -f 4)

if [ ! -f "$dir/minecraft/$minecraftVersion.jar" ]; then
    echo "Downloading $minecraftVersion..."
    curl -s -o "$dir/minecraft/$minecraftVersion.jar" "https://s3.amazonaws.com/Minecraft.Download/versions/$minecraftVersion/minecraft_server.$minecraftVersion.jar"
    if [ ! -f "$dir/minecraft/$minecraftVersion.jar" ]; then
        echo "ERROR: Minecraft failed to download!"
        exit 1
    fi
fi

if [ ! -f "$dir/minecraft/$minecraftVersion-spigot-cl.jar" ]; then
    echo "Applying Spigot Class Mappings..."
    java -jar "$dir/BuildData/bin/SpecialSource-2.jar" map -i "$dir/minecraft/$minecraftVersion.jar" -m "$classMappings" -o "$dir/minecraft/$minecraftVersion-spigot-cl.jar" 1>/dev/null
fi

if [ ! -f "$dir/minecraft/$minecraftVersion-spigot-m.jar" ]; then
    echo "Applying Spigot Member Mappings..."
    java -jar "$dir/BuildData/bin/SpecialSource-2.jar" map -i "$dir/minecraft/$minecraftVersion-spigot-cl.jar" -m "$memberMappings" -o "$dir/minecraft/$minecraftVersion-spigot-m.jar" 1>/dev/null
fi

if [ ! -f "$dir/minecraft/$minecraftVersion-spigot.jar" ]; then
    echo "Creating remapped jar..."
    java -jar "$dir/BuildData/bin/SpecialSource.jar" --kill-lvt -i "$dir/minecraft/$minecraftVersion-spigot-m.jar" --access-transformer "$accessTransforms" -m "$packageMappings" -o "$dir/minecraft/$minecraftVersion-spigot.jar" 1>/dev/null
fi

rm -f "$dir/minecraft/$minecraftVersion-mountain.jar"
java -jar "$dir/BuildData/bin/SpecialSource.jar" --kill-lvt -i "$dir/minecraft/$minecraftVersion-spigot.jar" -m "$dir/mountain.srg" -o "$dir/minecraft/$minecraftVersion-mountain.jar"
