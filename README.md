# Docker init

## Requirements

Docker Engine & Docker Compose (version >= 1.7): https://docs.docker.com/compose/install/

## Docker configuration

Recommended configuration in file /etc/default/docker

    DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --storage-driver=devicemapper"

After changing your docker configuration, restart the docker service

    sudo service docker restart

## Install

Install docker-init in your current directory:

    git clone git@github.com:c2is/docker-init.git
    sudo ln -s $(pwd)/docker-init/docker-init.sh /usr/local/bin/dockerinit

## Project configuration

Docker-init expects this directoy structure:

    /your-project-root
    --/docker
    ----config_resolver (optionnal)
    ----/dist
    ------docker-compose.yml.dist
    ------parameters.dist

### parameters.dist

Used to define parameters that will be made available to the docker-compose.yml file and any other file you might need to inject parameters into.
Parameters are defined as key value pairs separated by an equal sign. You can comment lines with #.

    # Apache configuration
    apache.port=81
    apache.host=my-hostname

The values defined in this file will be used as default when running dockerinit and can be overriden.
A special parameter named root_dir is implicitely added with a value equal to the directory where the dockerinit command is ran.

### config_resolver (optionnal)

Used to add files to be parsed by the dockerinit command to search and replace parameter values.
Default behaviour expects to be suffixed with .dist, when parsing the file the command will create a new file without the .dist suffix with the replaced parameter values.
You can override that behaviour and specify a source and destination name for your files with the > operator.

    docker/config/apache/vhost.conf.dist>docker/containers/apache/vhost.conf
    docker/config/php5/php.ini.dist

### docker-compose.yml.dist

This file is parsed by the command and a docker-compose.yml file is created with the parameter values replaced in the current directory.

## Usage

In your project root directory, use `dockerinit`

This command will ask for parameter values and create the docker-compose.yml file.
A parameters file will be created with the user values in the docker/ directory.

Use `dockerinit --help` to have more information about the command.

## Run Docker Compose

    docker-compose up -d --build

## Custom host

In most project a custom hostname will be used in a virtual host in the Apache / nginx configuration.
Add that host to your system hosts file with your Docker IP address.

To get your Docker IP:

    ifconfig docker0

In your /etc/hosts file add:

    <docker-ip> my-host-name

## generate-console

Used to create a wrapper for the Symfony console. Shown below are the available arguments and their default values.

    dockerinit generate-console --file=/var/www/symfony/bin/console --user=www-data --container=php 

## generate-composer

Used to create a wrapper for composer. Shown below are the available arguments and their default values.

    dockerinit generate-composer --user=www-data --working_dir=/var/www/symfony --container=php 

## Symfony usage

Run Symfony cli with `./docker/console` eg:

    ./docker/console cache:clear --env=prod --no-debug

Run composer cli with `./docker/composer` eg:

    ./docker/composer install
