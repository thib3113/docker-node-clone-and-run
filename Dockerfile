FROM node:lts-alpine
LABEL maintainer="citopia <citopia.fr>" version=1.0

RUN apk add --no-cache git bash openssh-client yarn

#add node_modules in cache
VOLUME /app/node_modules

WORKDIR /app

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["docker-entrypoint.sh"]
