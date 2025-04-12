FROM php:7.0-fpm

# Update sources to point to archived Debian Stretch repositories
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list \
    && sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list \
    && sed -i '/stretch-updates/d' /etc/apt/sources.list \
    && echo 'Acquire::Check-Valid-Until "0";' > /etc/apt/apt.conf.d/99disable-check-valid-until

# Set working directory
WORKDIR /var/www/src

# Continue with your installation steps...
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
    librabbitmq-dev

# Install Composer (locally available)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install supervisord, Nginx, and other system dependencies; configure PHP extensions
RUN apt-get -y update \
    && apt-get install -y nginx supervisor cron \
    && apt-get install -y libicu-dev \
    && docker-php-ext-install pdo_mysql mysqli mbstring zip exif pcntl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure intl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install soap \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install xsl

# Install GD
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
    && docker-php-ext-configure gd \
          --enable-gd-native-ttf \
          --with-freetype-dir=/usr/include/freetype2 \
          --with-png-dir=/usr/include \
          --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd \
    && docker-php-ext-enable gd

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Xdebug (commented out - uncomment and adjust version if needed)
RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
RUN pecl install xdebug-2.7.2;
RUN docker-php-ext-enable xdebug;

# Copy xdebug configuration for remote debugging if desired
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install composer globally (a second installation if needed)
RUN echo "Install composer globally"
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Install APCu and APCu BC
# RUN printf "\n" | pecl install apcu-beta && echo extension=apcu.so > /usr/local/etc/php/conf.d/10-apcu.ini
# RUN printf "\n" | pecl install apcu_bc-beta && echo extension=apc.so > /usr/local/etc/php/conf.d/apc.ini

# Install AMQP extension
# RUN printf "\n" | pecl install channel://pecl.php.net/amqp-1.7.0alpha2 && echo extension=amqp.so > /usr/local/etc/php/conf.d/amqp.ini

# Install EV extension
# RUN pecl install channel://pecl.php.net/ev-1.0.0RC3 && echo extension=ev.so > /usr/local/etc/php/conf.d/ev.ini

# Symlink logs to stdout/stderr so Docker can capture them
RUN ln -sf /dev/stdout /var/log/access.log && ln -sf /dev/stderr /var/log/error.log

# Add user for application
RUN groupadd -g 1000 www \
    && useradd -u 1000 -ms /bin/bash -g www www

# Change current user to www
USER www

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Note: Two CMD instructions are provided. The last one is what will actually be run.
# If you need to run both supervisord and php-fpm, consider using an entrypoint script.
CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
CMD ["php-fpm", "-R"]
