# Generate console file wrapper
# Default target is the symfony 3.0 console file
function console()
{
    force=false
    file="/var/www/symfony/bin/console"
    container="php"
    user="www-data"

    if ! options=$(getopt -o fu: -l force, file, container, user: -- "$@")
    then
        report "error" "$message_error_unexpected"
        exit 1
    fi

    accepted=("--force" "--file" "-f" "--container" "--user" "-u")

    while [ $# -gt 0 ]
    do
        case $1 in
        -f|--force)
            force=true
            ;;
        -u|--user)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_console_error_user"
                exit 1;
            fi

            user="$2";
            shift
            ;;
        --file)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_console_error_directory"
                exit 1;
            fi

            file="$2";
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

    if [ -f $current_path/docker/console ] && [ "$force" = true ]; then
        rm -rf $current_path/docker/console
    fi

    if [ ! -f $current_path/docker/console ]; then

cat <<EOF >> $current_path/docker/console
    #! /bin/bash
    echo -e "Running command: docker-compose run --user=$user $container $file \$@"
    echo -e "...............\n\n"

    eval "docker-compose run --user=$user $container $file \$@"
EOF

        chmod +x $current_path/docker/console
        report "success" "$messages_console_success";
    else
        report "warning" "$messages_console_exists";
    fi
}

# Generate composer file wrapper
function composer()
{
    force=false
    working_dir="/var/www/symfony"
    container="php"
    user="www-data"

    if ! options=$(getopt -o fu: -l force, working_dir, container, user: -- "$@")
    then
        report "error" "$message_error_unexpected"
        exit 1
    fi

    accepted=("--force" "-f" "--working_dir" "--container" "--user" "-u")

    while [ $# -gt 0 ]
    do
        case $1 in
        -f|--force)
            force=true
            ;;
        -u|--user)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_composer_error_user"
                exit 1;
            fi

            user="$2";
            shift
            ;;
        --working_dir)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_composer_error_working_dir"
                exit 1;
            fi

            working_dir="$2";
            shift
            ;;
        --container)
            if [[ -z $2 ]] || [[ ${accepted[*]} =~ "$2" ]]; then
                report "error" "$messages_composer_error_container"
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
            message=`printf "$messages_composer_error_options" "$0" "$1"`
            report "error" "$message";
            exit 1
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    if [ -f $current_path/docker/composer ] && [ "$force" = true ]; then
        rm -rf $current_path/docker/composer
    fi

    if [ ! -f $current_path/docker/composer ]; then

cat <<EOF >> $current_path/docker/composer
    #!/bin/bash
    echo -e "Running command: docker-compose run --user=$user $container composer \$@ --working-dir=$working_dir"
    echo -e "...............\n\n"

    docker-compose run --user=$user $container composer \$@ --working-dir=$working_dir
EOF

        chmod +x $current_path/docker/composer
        report "success" "$messages_composer_success";
    else
        report "warning" "$messages_composer_exists";
    fi

}