# Production configuration example

HTTPS support with Letsencrypt.

## Traefik configuration

Copy examples configuration files into _traefik_ folder.

* [Static configuration](traefik.yaml)
* [Dynamic configuration](config.yaml)

## Container configuration

Any container to expose through Traefik can use the following labels:

    networks:
        proxy:
            name: proxy
            attachable: true

    services:
        web:
            image: nginx
            # ...
            labels:
                - "traefik.enable=true"
                - "traefik.docker.network=proxy"
                - "traefik.http.routers.example.rule=Host(`example.org`)"
            networks:
                - default
                - proxy
