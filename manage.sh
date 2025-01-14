#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit

if [[ ! -f "./.env" ]]
then
    printf "Please create the .env file based on .env.dist"
    exit
fi

LOG_PATH="./docker_logs.txt"

source ./.env

# Clear logs
echo "" > ${LOG_PATH}

Success() {
    printf "\e[32m%s\e[0m\n" "$1"
}

Error() {
    printf "\e[31m%s\e[0m\n" "$1"
}

Warning() {
    printf "\e[31;43m%s\e[0m\n" "$1"
}

Help() {
    printf "\e[2m%s\e[0m\n" "$1"
}

DoneOrError() {
    if [[ $1 -eq 0 ]]
    then
        Success 'done'
    else
        Error 'error'
        exit 1
    fi
}

Confirm () {
    printf "\n"
    choice=""
    while [[ "$choice" != "n" ]] && [[ "$choice" != "y" ]]
    do
        printf "Do you want to continue ? (N/Y)"
        read -r choice
        choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')
    done
    if [[ "$choice" = "n" ]]; then
        printf "\nAbort by user.\n"
        exit 0
    fi
    printf "\n"
}

IsUpAndRunning() {
    if docker ps --format '{{.Names}}' | grep -q "$1\$"
    then
        return 0
    fi
    return 1
}

CheckProxyUpAndRunning() {
    if ! IsUpAndRunning traefik
    then
        Error "Proxy is not up and running."
        exit 1
    fi
}

NetworkExists() {
    if docker network ls --format '{{.Name}}' | grep -q "$1\$"
    then
        return 0
    fi
    return 1
}

ComposeUp() {
    if IsUpAndRunning traefik
    then
        Error "Already up and running."
        exit 1
    fi

    OPT=""
    if [[ $2 == 'up' ]]; then $OPT=" -f docker-compose.ui.yaml"; fi

    printf "Composing \e[1;33mup\e[0m ... "
    docker compose ${OPT} up -d >> ${LOG_PATH} 2>&1
    DoneOrError $?

    if [[ -f ./networks.list ]]
    then
        while IFS='' read -r NETWORK || [[ -n "$NETWORK" ]]; do
            if [[ "" != "${NETWORK}" ]]
            then
                Connect "${NETWORK}"
            fi
        done < ./networks.list

        sleep 1
        docker restart traefik
    fi
}

ComposeDown() {
    printf "Composing \e[1;33mdown\e[0m ... "
    docker compose down -v --remove-orphans >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

Execute() {
    CheckProxyUpAndRunning

    printf "Executing %s\n" "$1"

    printf "\n"

    docker exec -it traefik $1

    printf "\n"
}

Connect() {
    CheckProxyUpAndRunning

    NETWORK="$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if ! NetworkExists "${NETWORK}"
    then
        Error "Network '${NETWORK}' does not exist."
        exit
    fi

    printf "Connecting to \e[1;33m%s\e[0m network ... " "${NETWORK}"

    docker network connect "${NETWORK}" traefik >> ${LOG_PATH} 2>&1
    if [[ $? -ne 0 ]]
    then
        Error 'error'
        exit 1
    fi

    printf "\e[32mdone\e[0m\n"

    if [[ -f ./networks.list ]];
    then
        if [[ "$(cat ./networks.list | grep ${NETWORK})" ]]; then return 0; fi
    fi

    echo $1 >> ./networks.list
}

Reset() {
    ComposeDown
    printf "Clearing configured networks and certificates ... "

    if [[ -f ./networks.list ]]
    then
        rm ./networks.list
    fi

    if [[ -d ./letsencrypt/ ]]
    then
        rm -Rf ./letsencrypt/*
    fi

    printf "\e[32mdone\e[0m\n"
    ComposeUp
}

# ----------------------------- EXEC -----------------------------

case $1 in
    up)
        ComposeUp
    ;;
    down)
        ComposeDown
    ;;
    connect)
        Connect "$2"
    ;;
    restart)
        if ! IsUpAndRunning traefik
        then
            printf "\e[31mNot up and running.\e[0m\n"
            exit 1
        fi

        docker restart traefik
    ;;
    reset)
        Warning "Configured networks and certificates will be lost."

        Confirm

        Reset
    ;;
    *)
        printf "\e[2mUsage:  ./manage.sh [action] [options]

  \e[0mup\e[2m             Create and start containers for the [env] environment.
  \e[0mdown\e[2m           Stop and remove containers for the [env] environment.
  \e[0mgencert\e[2m name   Generates certificates for [name] domain.
  \e[0mconnect\e[2m name   Connects proxy to [name] network.
  \e[0mrestart\e[2m        Restart nginx container.
  \e[0mreset\e[2m          Reset the containers and network connections.
\e[0m"
    ;;
esac

printf "\n"
