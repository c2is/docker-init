#!/bin/bash

. "$library_path/yaml_parser.sh"

eval $(parse_yaml "$config_path/messages.yml" "messages_")

# Initiate
# $1: optional action [reset, purge]
init () {
    if [ ! -z $1 ]; then
        optional $1
    fi

    if [ -f $current_path/docker/parameters ] || [ -f $current_path/docker/docker-compose.yml ]; then
        report "error" "$messages_error_exists";
        exit 1;
    fi

    if [ ! -f $dist_path/parameters.dist ] && [ ! -f $dist_path/docker-compose.yml.dist ]; then
        report "error" "$messages_error_required_files";
        exit 1;
    fi

    if [ ! -f "$current_path/docker/parameters" ]; then
        parse_config "$dist_path/parameters.dist" "$current_path/docker/parameters"
    fi

    if [ ! -f "$current_path/docker/docker-compose.yml" ]; then
        replace_config "$current_path/docker/parameters" "$dist_path/docker-compose.yml.dist" "$current_path/docker/docker-compose.yml"
    fi

    config_resolver "$current_path/docker/parameters"

    echo "end";
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

# Generate console file
function console()
{
    if [ ! -f $current_path/docker/console ]; then

cat <<EOF >> $current_path/docker/console
    #! /bin/bash
    echo -e "Running command: docker-compose run php /var/www/symfony/app/console $@"
    echo -e "...............\n\n"

    eval "docker-compose run php /var/www/symfony/app/console $@"
EOF

        chmod +x $current_path/docker/console
        report "success" "$messages_console_success";
    else
        report "warning" "$messages_console_exists";
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
        rm -Rf $current_path/docker/docker-compose.yml
        rm -Rf $current_path/docker/parameters
        ;;
    'generate_console' )
        console
        exit 0;
    esac
}