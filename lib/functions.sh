#!/bin/bash

# Report a message to print or log
# $1 : type of report
# $2 : message to report
# $3 : add to log file (default: false)
function report {
	date_tag="["$(date +"%Y-%m-%d %H:%M:%S")"] "
	log_light="$2"
	log_all="${@:2}"
	add_to_log=$3
	: ${add_to_log:=false}

	screen_log=$log_light

	case $1 in
		"screen" )
	        echo -e $screen_log;
	        ;;
	    "info" )
	        echo -e "$screen_log";
	        ;;
	   	"success" )
	        echo -e $green"$screen_log"$white;
	        ;;
	    "warning" )
	        echo -e $yellow"$screen_log"$white;
	        ;;
	    "error" )
	        echo -e $red"$screen_log"$white;
	        add_to_log=true
	        ;;
	esac

	if [ $add_to_log == true ]; then
        printf "\n$date_tag%s" "$log_all" >> $log_file;
    fi
}

# Parse configuration file
# Load configuration from file and output a file
# $1: string the input file
# $2: string the output file
function parse_config()
{
    i=0

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ ! -z "$line" ] && [[ ${line:0:1} != "#" ]]; then
            params[$i]=${line%=*}
            values[$i]=${line/*=}

            ((++i))
        fi
    done < "$1"

    if [ ! -z params ] && [ ! -z values ]; then
        for i in "${!params[@]}"; do
            param=${params[$i]}
            value=${values[$i]}

            read -p "$param ($value): " input

            if [ ! -z $input ]; then
                echo "$param=$input"
            else
                echo "$param=$value"
            fi
        done > "$2"
    fi
}

# Replace value from configuration
# $1: string the input file
# $2: string the source file
function replace_config()
{
    i=0

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ ! -z "$line" ] && [[ ${line:0:1} != "#" ]]; then
            params[$i]=${line%=*}
            values[$i]=${line/*=}

            ((++i))
        fi
    done < "$1"


    if [ ! -z params ] && [ ! -z values ]; then
        cp "$2" "$3"

        for i in "${!params[@]}"; do
            param=${params[$i]}
            search="{{${param}}}"
            replace=${values[$i]}

            sed -e "s/${search}/${replace}/g" $3 > "$current_path/_${3##*/}"
            mv "$current_path/_${3##*/}" $3
        done
    fi
}

# Config resolver
# $1: source parameters file
function config_resolver()
{
    if [ -f "$current_path/docker/config_resolver" ]; then
        i=0

        while IFS='' read -r line || [[ -n "$line" ]]; do
            if [ ! -z "$line" ] && [[ ${line:0:1} != "#" ]]; then
                params[$i]=${line%=*}
                values[$i]=${line/*=}

                ((++i))
            fi
        done < "$1"

        while IFS='' read -r line || [[ -n "$line" ]]; do
            if [ ! -z "$line" ] && [[ ${line:0:1} != "#" ]]; then
                files[$i]=${line}

                ((++i))
            fi
        done < "$current_path/docker/config_resolver"

        if [ ! -z params ] && [ ! -z values ]; then
            for file in "${files[@]}"; do
                filename=${file%.dist}

                if [ ! -f $filename ]; then
                    message=`printf "$messages_error_config_resolver_not_found" "$filename"`
                    report "error" "$message"
                    continue
                fi

                `cp ${file} ${filename}`

                for i in "${!params[@]}"; do
                    param=${params[$i]}
                    search="{{${param}}}"
                    replace=${values[$i]}

                    sed -e "s/${search}/${replace}/g" $filename > "$current_path/_${filename##*/}"
                    mv "$current_path/_${filename##*/}" $filename
                done
            done
        fi
    fi
}