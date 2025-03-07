# Production configuration example

HTTPS support with Letsencrypt.

## Traefik configuration

Copy examples configuration files into _traefik_ folder.

* [Static configuration](traefik.yaml)
* [Dynamic configuration](config.yaml)

## Container configuration

Any container to expose through Traefik can use the following labels:

    services:
        web:
            image: nginx
            # ...
            labels:
                - "traefik.enable=true"
                - "traefik.http.routers.example.rule=Host(`example.org`) || Host(`www.example.org`)"
                - "traefik.http.routers.example.tls=true"
                # Optionnal www to non-www redirection
                - "traefik.http.middlewares.wwwredirect=true"
