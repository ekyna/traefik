# Development configuration example

HTTPS support with local trusted certificates.

## MKCERT

Install [mkcert](https://github.com/FiloSottile/mkcert):

    apt install mkcert

Create a root CA:
    
    mkcert -install
    
Add the root CA to the trusted CA store:

    # Displays the path of the generated root CA 
    mkcert -CAROOT

Create _docker.local_ domain certificate:

    mkdir ./traefik/certs
    mkcert \
        -cert-file ./traefik/certs/local-cert.pem \
        -key-file ./traefik/certs/local-key.pem \
        "docker.local" "*.docker.local"

## Traefik configuration

Copy examples configuration files into _traefik_ folder.

* [Static configuration](traefik.yaml)
* [Dynamic configuration](config.yaml)

## Use basic auth for dashboard security

Install htpasswd utility:

    apt install apache2-utils

Generate credentials:

    htpasswd -nB user

Put credentials into traefik/config/.htpasswd.

## Container configuration

Any container to expose through Traefik can use the following labels:

    services:
        web:
            image: nginx
            # ...
            labels:
                - "traefik.enable=true"
                - "traefik.http.routers.example.rule=Host(`example.docker.local`)"

## Resources

* [Traefik v2 HTTPS (SSL) en localhost](https://zestedesavoir.com/billets/3355/traefik-v2-https-ssl-en-localhost/)