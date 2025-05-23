#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit

if [[ ! -f "./.env" ]]
then
    printf "Please create the ./.env file based on ./.env.dist\n"
    exit
fi

if [[ ! -f "./traefik/traefik.yaml" ]]
then
    printf "Please create the ./traefik/traefik.yaml file (see examples folder)\n"
    exit
fi

LOG_PATH="./log/docker.txt"

source ./.env

# Clear logs
echo "" > ${LOG_PATH}

COMPOSE_OPT="-f ./compose.yaml --env-file=.env"

Success() {
    printf "\e[32m%s\e[0m\n" "$1"
}

Error() {
    printf "\e[31m%s\e[0m\n" "$1"
}

Warning() {
    printf "\e[31;43m%s\e[0m\n" "$1"
}

Comment() {
    printf "\e[36m%s\e[0m\n" "$1"
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

    printf "\n"

    if [[ "$choice" = "n" ]]; then
        Warning "Abort by user."
        exit 0
    fi
}

IsUpAndRunning() {
    if docker ps --format '{{.Names}}' | grep -q "$1\$"
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

    printf "Composing \e[1;33mup\e[0m ... "
    docker compose ${COMPOSE_OPT} up -d >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

ComposeDown() {
    printf "Composing \e[1;33mdown\e[0m ... "
    docker compose ${COMPOSE_OPT} down -v --remove-orphans >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

# ----------------------------- EXEC -----------------------------

case $1 in
    up)
        ComposeUp
    ;;
    down)
        ComposeDown
    ;;
    restart)
        if ! IsUpAndRunning traefik
        then
            Error "Not up and running."
            exit 1
        fi

        docker restart traefik
    ;;
    *)
        printf "\e[2mUsage:  ./manage.sh [action]

  \e[0mup\e[2m         Create and start containers.
  \e[0mdown\e[2m       Stop and remove containers.
  \e[0mrestart\e[2m    Restart traekif container.

\e[0m"
    ;;
esac

printf "\n"
