#!/bin/bash

. "$library_path/yaml_parser.sh"

eval $(parse_yaml "$config_path/messages.yml" "messages_")

# Initiate
# $1: optional action [reset, purge]
init () {
    docker_compose_path=$current_path/docker-compose.yml

    if [ ! -z $1 ]; then
        optional $@
    fi

    if [ -f "$current_path/docker/parameters" ] || [ -f "$docker_compose_path" ]; then
        report "error" "$messages_error_exists";
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
# Default target is the symfony 3.0 console file
function console()
{
    force=false
    project="/var/www/symfony/bin/console"
    container="php"

    if ! options=$(getopt -o f: -l force, project: -- "$@")
    then
        report "error" "$message_error_unexpected"
        exit 1
    fi

    accepted=("--force" "--project" "--container")

    while [ $# -gt 0 ]
    do
        case $1 in
        -f|--force)
            force=true
            ;;
        --project)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_console_error_directory"
                exit 1;
            fi

            project="$2";
            shift
            ;;
        --container)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_console_error_container"
                exit 1;
            fi

            container="$2";
            shift
            ;;
        --)
            shift;
            break
            ;;
        -*)
            message=`printf "$messages_console_error_options" "$0" "$1"`
            report "error" "$message";
            exit 1
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    if [ -f $current_path/docker/console ] && [ force ]; then
        rm -rf $current_path/docker/console
    fi

    if [ ! -f $current_path/docker/console ]; then

cat <<EOF >> $current_path/docker/console
    #! /bin/bash
    echo -e "Running command: docker-compose run $container $project \$@"
    echo -e "...............\n\n"

    eval "docker-compose run $container $project \$@"
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
        rm -Rf $current_path/docker-compose.yml
        rm -Rf $current_path/docker/parameters
        ;;
    'generate-console' )
        console ${@:2}
        exit 0;
    esac
}