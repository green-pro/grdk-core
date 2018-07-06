FROM php:7.0-apache
ADD config.php /var/www/html/
ADD send.php /var/www/html/
ADD gitlab-webhook.php /var/www/html/
RUN chown -R www-data:www-data /var/www/html
