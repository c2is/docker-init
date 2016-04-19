#!/bin/bash

if [ "$(uname)" != "Linux" ]; then
    path=`readlink "$0"`
else
    path=`readlink -f "$0"`
fi

absolute_path=$(dirname "$path")
library_path="$absolute_path/lib"
config_path="$absolute_path/config"
current_path=`pwd`
dist_path="$current_path/docker/dist"

if [ ! -d $absolute_path/log ]; then
    mkdir $absolute_path/log
fi

log_file=$absolute_path/log/$(date +%Y%m%d).log

count=`ls $absolute_path/log/ | wc -l`

if [ $count -ne 0 ]; then
    rm -rf `find $absolute_path/log/* -mmin +720 -type f`
fi

. "$library_path/vars.sh"
. "$library_path/functions.sh"
. "$library_path/init.sh"

init $@

exit;