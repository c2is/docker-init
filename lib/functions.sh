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
	        echo -e $cyan"$screen_log"$white;
	        ;;
	    "debug" )
	        echo -e $purple"[debug] $screen_log"$white;
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
    report "info" "$messages_tasks_parse_config"

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

            if [ $3 == true ]; then
                read -p "$param ($value): " input

                if [ ! -z $input ]; then
                    echo "$param=$input"
                else
                    echo "$param=$value"
                fi
            else
                echo "$param=$value"
            fi
        done > "$2"
    fi

    if [ $3 == false ]; then
        message=`printf "$messages_parse_config_no_interaction" "$2"`
        report "warning" "$message"
    fi

    echo "root_dir=$current_path" >> $2
}

# Replace value from configuration
# $1: string the input file
# $2: string the source file
function replace_config()
{
    report "info" "$messages_tasks_replace_config"

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

            sed "s|${search}|${replace}|g" $3 > "$current_path/_${3##*/}"
            mv "$current_path/_${3##*/}" $3
        done
    fi
}

# Config resolver
# $1: source parameters file
function config_resolver()
{
    report "info" "$messages_tasks_config_resolver";

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
                if [[ $file =~ ">" ]]; then
                    source=${file%\>*}
                    destination=${file/*\>}
                else
                    source=${file}
                    destination=${file%.dist}
                fi

                `cp ${source} ${destination}`

                for i in "${!params[@]}"; do
                    param=${params[$i]}
                    search="{{${param}}}"
                    replace=${values[$i]}

                    sed -e "s|${search}|${replace}|g" $destination > "$current_path/_${filename##*/}"
                    mv "$current_path/_${filename##*/}" $destination
                done

                message=`printf "$messages_config_resolver_file" "$destination"`

                report "screen" "$message";
            done
        fi
    fi
}

# Get config
# $1: parameter name
# $2: default value
function get_config()
{
    if [ ! -f "$current_path/docker/parameters" ]; then
        report "error" "$messages_get_config_error_parameters"
        exit 1
    fi

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ ! -z "$line" ] && [[ ${line:0:1} != "#" ]]; then
            param=${line%=*}
            value=${line/*=}

            if [ "$1" == "$param" ]; then
                echo $value
                exit 0
            fi
        fi
    done < "$current_path/docker/parameters"

    if [[ $2 ]]; then
        echo $2
        exit 0
    fi

    exit 1
}

# Help
function help()
{
    less "$doc_path/dockerinit.help"
}