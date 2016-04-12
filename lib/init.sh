#!/bin/bash

. "$library_path/yaml_parser.sh"
. "$library_path/wrapper.sh"

eval $(parse_yaml "$config_path/messages.yml" "messages_")

# Initiate
# $1: optional action [reset, purge]
init () {
    docker_compose_path=$current_path/docker-compose.yml

    if [ ! -z $1 ]; then
        optional $@
    fi

    if [ -f "$current_path/docker/parameters" ] || [ -f "$docker_compose_path" ]; then
        files=""

        if [ -f "$current_path/docker/parameters" ]; then
            files+=" $current_path/docker/parameters"
        fi

        if [ -f "$docker_compose_path" ]; then
            files+=" $docker_compose_path"
        fi

        message=`printf "$messages_init_error_exists" "$files"`
        report "error" "$message";
        exit 1;
    fi

    if [ ! -f "$dist_path/parameters.dist" ] && [ ! -f "$dist_path/dist/docker-compose.yml.dist" ]; then
        report "error" "$messages_error_required_files";
        exit 1;
    fi

    if [ ! -f "$current_path/docker/parameters" ]; then
        parse_config "$dist_path/parameters.dist" "$current_path/docker/parameters"
    fi

    if [ ! -f "$docker_compose_path" ]; then
        replace_config "$current_path/docker/parameters" "$dist_path/docker-compose.yml.dist" "$docker_compose_path"
    fi

    config_resolver "$current_path/docker/parameters"

    report "info" "$messages_tasks_done";
    exit 0;
}

# Clean up
# Stop and remove docker container
function purge()
{
    count=`docker ps -q | wc -l`

    if [ $count -ne 0 ]; then
        docker stop $(docker ps -q)
    fi

    count=`docker ps -q -a | wc -l`

    if [ $count -ne 0 ]; then
        docker stop $(docker ps -q)
    fi
}

# Reset
# Call with the reset option
# Remove dist generated files
function reset()
{
    if [ -f $current_path/docker-compose.yml ]; then
        rm -Rf $current_path/docker-compose.yml
    fi

    if [ -f $current_path/docker/parameters ]; then
        rm -Rf $current_path/docker/parameters
    fi
}

# Clear
# Call with the clear option
# Remove generate console and composer files
function clear()
{
    reset

    if [ -f $current_path/docker/console ]; then
        rm -Rf $current_path/docker/console
    fi

    if [ -f $current_path/docker/composer ]; then
        rm -Rf $current_path/docker/composer
    fi
}

# Optional
# Execute optional actions
# $1: optional action
function optional()
{
    case "$1" in
    'purge' )
        purge
        ;;
    'reset' )
        reset
        ;;
    'clear' )
        clear
        exit 0;
        ;;
    'generate-console' )
        console ${@:2}
        exit 0
        ;;
    'generate-composer' )
        composer ${@:2}
        exit 0
        ;;
    'get_config' )
        get_config ${@:2}
        exit 0
        ;;
    esac
}