FROM php:7.2-fpm

# Set working directory
WORKDIR /var/www/src

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install dependencies
# RUN apt-get -y update --fix-missing
RUN apt-get update && apt-get install -y \
    build-essential \
    libmcrypt-dev \
    libpng-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    libxslt-dev \
    curl \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libfreetype6-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libgmp-dev \
    libsodium-dev \
    librabbitmq-dev

# Install supervisord
RUN apt-get -y update \
    && apt-get install -y nginx supervisor cron \
    && apt-get install -y libicu-dev \
    && docker-php-ext-install pdo_mysql mysqli mbstring zip exif pcntl \
    && docker-php-ext-install intl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install soap \
    && docker-php-ext-install gmp \
    && docker-php-ext-install xsl \
    && docker-php-ext-configure intl \
    && docker-php-ext-enable sodium

# Install GD
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install xdebug
RUN if [ ${INSTALL_XDEBUG} ]; then \
 # Install the xdebug extension
 if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
   pecl install xdebug-2.5.5; \
 else \
   if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
     pecl install xdebug-2.9.0; \
   else \
     pecl install xdebug-2.9.8; \
   fi \
 fi && \
 docker-php-ext-enable xdebug \
;fi

# Copy xdebug configuration for remote debugging
#COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install xdebug
# RUN pecl install php-xdebug \
#     && docker-php-ext-enable php-xdebug

# Install composer globally
RUN echo "Install composer globally"

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

RUN printf "\n" | pecl install apcu-beta && echo extension=apcu.so > /usr/local/etc/php/conf.d/10-apcu.ini
RUN printf "\n" | pecl install apcu_bc-beta && echo extension=apc.so > /usr/local/etc/php/conf.d/apc.ini

RUN printf "\n" | pecl install channel://pecl.php.net/amqp-1.7.0alpha2 && echo extension=amqp.so > /usr/local/etc/php/conf.d/amqp.ini

RUN pecl install channel://pecl.php.net/ev-1.0.0RC3 && echo extension=ev.so > /usr/local/etc/php/conf.d/ev.ini

RUN ln -sf /dev/stdout /var/log/access.log && ln -sf /dev/stderr /var/log/error.log

# Add user for application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

CMD ["php-fpm", "-R"]

