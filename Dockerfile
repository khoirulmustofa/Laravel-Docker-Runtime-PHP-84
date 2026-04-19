FROM ubuntu:24.04

LABEL maintainer="Form Taylor Otwell"

ARG WWWGROUP=33            # 33 adalah grup www-data di Debian/Ubuntu
ARG NODE_VERSION=24
ARG MYSQL_CLIENT="mysql-client"
ARG POSTGRES_VERSION=18

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta
# Tidak pakai artisan serve lagi
# ENV SUPERVISOR_PHP_COMMAND=...
ENV SUPERVISOR_PHP_USER="www-data"
ENV PLAYWRIGHT_BROWSERS_PATH=0 

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Optional apt tuning
RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

# Base packages + Nginx + Supervisor
RUN apt-get update && apt-get upgrade -y \
 && mkdir -p /etc/apt/keyrings \
 && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python3 dnsutils librsvg2-bin ffmpeg nano nginx

# PHP 8.4 (Ondřej PPA)
RUN curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xb8dc7e53946656efbce4c1dd71daeaab4ad4cab6' \
 | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
 && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" \
    > /etc/apt/sources.list.d/ppa_ondrej_php.list \
 && apt-get update \
 && apt-get install -y php8.4-fpm php8.4-cli php8.4-dev \
    php8.4-pgsql php8.4-sqlite3 php8.4-gd \
    php8.4-curl php8.4-mongodb \
    php8.4-imap php8.4-mysql php8.4-mbstring \
    php8.4-xml php8.4-zip php8.4-bcmath php8.4-soap \
    php8.4-intl php8.4-readline \
    php8.4-ldap \
    php8.4-msgpack php8.4-igbinary php8.4-redis php8.4-swoole \
    php8.4-memcached php8.4-pcov php8.4-imagick php8.4-xdebug

# Composer
RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Node 22 + npm + yarn
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update && apt-get install -y nodejs \
 && npm install -g npm \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
 && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt-get update && apt-get install -y yarn

# DB clients (opsional)
RUN curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
 && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y $MYSQL_CLIENT postgresql-client-$POSTGRES_VERSION \
 && apt-get -y autoremove && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Izinkan bind <1024 jika perlu (opsional)
RUN setcap "cap_net_bind_service=+ep" /usr/sbin/php-fpm8.4 || true

# Pastikan user www-data dipakai
# (www-data sudah ada di Ubuntu dengan UID 33 / GID 33)
RUN userdel -r ubuntu || true
RUN groupmod -g ${WWWGROUP} www-data || true

# Konfigurasi (COPY dari folder docker/*)
COPY nginx/nginx.conf            /etc/nginx/nginx.conf
COPY nginx/default.conf          /etc/nginx/conf.d/default.conf
COPY php/php.ini                 /etc/php/8.4/fpm/conf.d/99-custom.ini
COPY php/www.conf                /etc/php/8.4/fpm/pool.d/www.conf
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-container             /usr/local/bin/start-container

RUN chmod +x /usr/local/bin/start-container \
 && mkdir -p /run/nginx /run/php /var/log/nginx /var/log/php-fpm \
 && chown -R www-data:www-data /run/nginx /run/php /var/log/nginx /var/log/php-fpm

EXPOSE 80
ENTRYPOINT ["start-container"]
CMD ["supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
