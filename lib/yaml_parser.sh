#!/bin/bash

# Parse yaml file
# $1: the file to parse
# $2: prefix for the global variable
parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"

    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" | sed "s/\/$//" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    if (id != vname[1]) {
            id=vname[1];
            printf("ids+=(%s)\n", vname[1]);
        }
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}

            printf("%s%s%s=(\"%s\");\n", "'"$prefix"'",vn, $2, $3);
        }
    }' | sed 's/_=/+=/g'
}