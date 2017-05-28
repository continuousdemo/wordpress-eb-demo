FROM php:7.0-fpm
RUN  docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql 
RUN sed -ri 's/^www-data:x:33:33:/www-data:x:1000:50:/' /etc/passwd
