FROM nginx
EXPOSE 80

ADD deploy/gulimall.conf /etc/nginx/conf.d
ADD dist /usr/share/nginx/html
ENTRYPOINT [nginx -g "daemon -off"]