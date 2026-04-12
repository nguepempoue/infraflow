FROM nginxinc/nginx-unprivileged:1.27-alpine

USER root
RUN apk upgrade --no-cache libcrypto3 libssl3 libxml2
USER 101

COPY --chown=101:101 nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
