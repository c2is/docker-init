# Docker init

## Requirements

Docker Engine & Docker Compose (version >= 1.7): https://docs.docker.com/compose/install/

## Docker configuration

Recommended configuration in file /etc/default/docker

    DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --storage-driver=devicemapper"

After changing your docker configuration, restart the docker service

    sudo service docker restart

## Custom host

In most project a custom hostname will be used in a virtual host in the Apache / nginx configuration.
Add that host to your system hosts file with your Docker IP address.

To get your Docker IP:

    ifconfig docker0

In your /etc/hosts file add:
    <docker-ip> my-host-name

## Install

Install docker-init in your current directory:

    git clone git@github.com:haflit21/docker-init.git
    sudo ln -s $(pwd)/docker-init/docker-init.sh /usr/local/bin/dockerinit

## Usage

In your project root directory, use:

    dockerinit

This command will ask for your input to setup the project's docker-compose.yml.

## Run Docker Compose

    docker-compose up -d --build

## Setup Symfony

    dockerinit generate-console --file /var/www/symfony/app/console
    dockerinit generate-composer

## Usage

Run Symfony cli with:
    ./docker/console

Run composer cli with:
    ./docker/composer install
