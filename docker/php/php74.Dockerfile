FROM php:7.4-fpm

# Set working directory
WORKDIR /var/www/src

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
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
    libjpeg-dev

# Install supervisord
RUN apt-get -y update \
    && apt-get install -y nginx supervisor cron \
    && apt-get install -y libicu-dev \
    && docker-php-ext-install pdo_mysql mysqli mbstring zip exif pcntl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install gd \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install soap \
    && docker-php-ext-install xsl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Add user for application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000

CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
CMD ["php-fpm", "-R"]

