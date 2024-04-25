# PHP-FPM stage
FROM php:8.2-fpm AS php_base

WORKDIR /var/www/

# Install PHP extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions pdo pdo_mysql mysqli gd opcache intl zip calendar dom mbstring xsl

# Install APCu for caching
RUN pecl install apcu && docker-php-ext-enable apcu

# Install Composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php

# Install additional necessary packages
RUN apt update && apt install -yqq locales coreutils apt-utils libicu-dev g++ libpng-dev libxml2-dev libzip-dev libonig-dev libxslt-dev git

# Install Symfony CLI tool
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

# Clean up the package manager to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for Symfony (production)
RUN \
    touch .env && \
    echo "APP_ENV=prod" >> .env && \
    echo "APP_DEBUG=0" >> .env && \
    echo "APP_SECRET=92d36690c31f1efd2bb3f444bcee3a4c" >> .env && \
    echo "DATABASE_URL=\"mysql://root:7Ji34yE5LckM@db:3306/app?serverVersion=5.7&charset=utf8mb4\"" >> .env

# Install composer dependencies
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer self-update 2.6.6

COPY . .

# Create files
RUN mkdir /var/www/var
RUN mkdir /var/www/var/cache /var/www/var/log /var/www/var/sessions
RUN mkdir /var/www/var/cache/prod
RUN mkdir /var/www/var/cache/prod/asset_mapper

# Adjust permissions and ownership
RUN chmod -R 755 /var/www/var/cache /var/www/var/log /var/www/var/sessions && \
    chown -R www-data:www-data /var/www
RUN chmod -R 755 /var/www/var/cache/prod/asset_mapper

RUN composer install --prefer-dist --no-interaction

RUN apt-get update && apt-get install -y \
    software-properties-common \
    npm

RUN npm install

COPY . ./

RUN npm run build

# Expose port
EXPOSE 6969

# Start the Symfony server
CMD ["symfony", "serve", "--port=6969", "--allow-http", "--no-tls"]

