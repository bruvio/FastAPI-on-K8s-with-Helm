#!/bin/sh
set -e

envsubst '${LISTEN_PORT} ${APP_HOST} ${APP_PORT} ${S3_STORAGE_BUCKET_NAME} ${S3_STORAGE_BUCKET_REGION}' \
  < /etc/nginx/default.conf.tpl \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
