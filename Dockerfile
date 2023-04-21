FROM nginx:latest
EXPOSE 80

ADD deploy/gulimall.conf /etc/nginx/conf.d
ADD dist /usr/share/nginx