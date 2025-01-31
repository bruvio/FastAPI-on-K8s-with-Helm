FROM nginxinc/nginx-unprivileged:1-alpine
LABEL maintainer="bruno.viola@pm.me"

COPY ./default.conf.tpl.local /etc/nginx/default.conf.tpl
COPY ./uwsgi_params /etc/nginx/uwsgi_params

ENV LISTEN_PORT=8000
ENV APP_HOST=app
ENV APP_PORT=9000
ENV S3_STORAGE_BUCKET_NAME="my-api-avatars"
ENV S3_STORAGE_BUCKET_REGION="eu-west-2"

USER root

RUN mkdir -p /vol/static
RUN chmod 755 /vol/static
RUN touch /etc/nginx/conf.d/default.conf
RUN chown nginx:nginx /etc/nginx/conf.d/default.conf


COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER nginx

CMD ["/entrypoint.sh"]
