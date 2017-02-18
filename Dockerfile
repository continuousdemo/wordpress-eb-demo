FROM php:7.0-fpm
RUN  docker-php-ext-install mysqli && docker-php-ext-install pdo_mysql 
