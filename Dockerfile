FROM php:8.0-apache

LABEL maintainer="LGNewUi"
LABEL description="LGNewUi - 恋爱纪念主题网站程序"

RUN sed -i 's|deb.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libzip-dev \
        libonig-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libicu-dev \
        libmagickwand-dev \
        libsqlite3-dev \
        zlib1g-dev \
        libgmp-dev \
        ffmpeg \
        default-mysql-client \
        unzip \
        wget \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
        bcmath exif gettext gmp intl mysqli opcache pcntl \
        pdo_mysql shmop soap sockets sysvsem zip \
    && ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20200930/zip.so

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install gd \
    && ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20200930/gd.so

RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20200930/imagick.so

RUN apt-mark manual libmagickwand-6.q16-6 libmagickcore-6.q16-6 libzip4 \
    && apt-get purge -y --auto-remove \
        libonig-dev libxml2-dev libcurl4-openssl-dev libssl-dev \
        libicu-dev libsqlite3-dev zlib1g-dev libgmp-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY loaders/ixed.8.0.lin /usr/local/lib/php/extensions/no-debug-non-zts-20200930/
RUN echo "extension=ixed.8.0.lin" > /usr/local/etc/php/conf.d/sourceguardian.ini

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_time=300'; \
    echo 'memory_limit=256M'; \
    echo 'date.timezone=Asia/Shanghai'; \
    echo 'include_path=".:/usr/local/lib/php:/var/www/html"'; \
} > /usr/local/etc/php/conf.d/lgnewui.ini \
    && a2enmod rewrite headers ssl deflate expires remoteip \
    && { \
        echo '<IfModule remoteip_module>'; \
        echo '    RemoteIPHeader X-Forwarded-For'; \
        echo '    RemoteIPInternalProxy 127.0.0.1'; \
        echo '    RemoteIPInternalProxy 172.16.0.0/12'; \
        echo '    RemoteIPInternalProxy 10.0.0.0/8'; \
        echo '    RemoteIPInternalProxy 192.168.0.0/16'; \
        echo '</IfModule>'; \
    } > /etc/apache2/conf-available/remoteip.conf \
    && a2enconf remoteip

WORKDIR /var/www/html

COPY . /var/www/html/

RUN rm -f /usr/local/lib/php/sg_intercept.php

RUN mkdir -p /var/www/html/uploads \
    /var/www/html/Lovefolder \
    /var/www/html/storage/updates \
    /var/www/html/storage/logs \
    /var/www/html/storage/cache \
    /var/www/html/storage/runtime \
    /var/www/html/storage/weather_api \
    /var/www/html/storage/jobs \
    /var/www/html/storage/packages \
    /var/www/html/storage/staging \
    /var/www/html/storage/backups \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/uploads \
    && chmod -R 775 /var/www/html/Lovefolder \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/install

RUN echo '#!/bin/bash\n\
set -e\n\
mkdir -p /var/www/html/uploads /var/www/html/Lovefolder\n\
mkdir -p /var/www/html/storage/updates\n\
mkdir -p /var/www/html/storage/logs\n\
mkdir -p /var/www/html/storage/cache\n\
mkdir -p /var/www/html/storage/runtime\n\
mkdir -p /var/www/html/storage/weather_api\n\
mkdir -p /var/www/html/storage/jobs\n\
mkdir -p /var/www/html/storage/packages\n\
mkdir -p /var/www/html/storage/staging\n\
mkdir -p /var/www/html/storage/backups\n\
chown -R www-data:www-data /var/www/html/uploads /var/www/html/Lovefolder /var/www/html/storage\n\
chmod -R 775 /var/www/html/uploads /var/www/html/Lovefolder /var/www/html/storage\n\
exec apache2-foreground' > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
CMD ["/usr/local/bin/docker-entrypoint.sh"]