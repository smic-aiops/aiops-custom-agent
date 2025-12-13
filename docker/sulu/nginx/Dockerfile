FROM nginx:1.25-alpine

COPY default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /var/www/html/public/uploads/media \
    && chown -R 101:101 /var/www/html
