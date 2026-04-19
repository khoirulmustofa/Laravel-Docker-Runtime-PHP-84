# Laravel Docker Runtime (PHP 8.4)

A production-ready, high-performance Docker base image designed specifically for Laravel applications. This image comes pre-configured with a modern stack including Nginx, PHP-FPM 8.4, and essential tools for Laravel development and deployment.

## 🚀 Features

- **Base OS**: Ubuntu 24.04 (Noble Numbat)
- **PHP**: 8.4 (Ondřej Surý PPA)
    - Extensions: `fpm`, `cli`, `mysql`, `pgsql`, `sqlite3`, `redis`, `swoole`, `mongodb`, `gd`, `zip`, `bcmath`, `xml`, `intl`, `mbstring`, `imagick`, and more.
- **Web Server**: Nginx (configured as a reverse proxy for PHP-FPM)
- **Process Manager**: Supervisor (manages both Nginx and PHP-FPM)
- **Node.js**: 22.x (includes `npm` and `yarn`)
- **Other Tools**:
    - Composer
    - Git, Zip, Unzip
    - MySQL & PostgreSQL clients
    - ImageMagick, FFmpeg
    - Healthcheck script

## 🛠 Project Explanation

This project provides a "batteries-included" runtime environment. Instead of setting up PHP and Nginx manually for every project, you can use this image as a base to ensure consistency across environments.

The container is managed by **Supervisor**, which ensures that both the web server (Nginx) and the PHP processor (PHP-FPM) are running. If either crashes, Supervisor will attempt to restart them.

The default web root is set to `/var/www/html/public`, adhering to Laravel's standard directory structure.

## 📦 How to Build

### Local Build
To build the image locally:

```bash
docker build -t laravel-runtime-84 .
```

### Build & Push to GHCR
If you want to push this to GitHub Container Registry:

```bash
# Login (use your PAT)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Build and Tag
docker build -t ghcr.io/YOUR_USERNAME/laravel-docker-runtime-php-84:latest .

# Push
docker push ghcr.io/YOUR_USERNAME/laravel-docker-runtime-php-84:latest
```

## 📖 How to use in your Laravel Project

To use this image in your Laravel project's `Dockerfile`, simply refer to it in the `FROM` instruction.

### Example `Dockerfile`

```dockerfile
# Use this runtime as the base
FROM ghcr.io/khoirulmustofa/laravel-docker-runtime-php-84:latest

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY --chown=www-data:www-data . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install Node dependencies and build assets
RUN npm install && npm run build

# Final permissions check (handled by start-container but good to ensure)
RUN chown -R www-data:www-data storage bootstrap/cache
```

## ⚙️ Configuration Paths

- **Nginx Config**: `/etc/nginx/nginx.conf` and `/etc/nginx/conf.d/default.conf`
- **PHP Config**: `/etc/php/8.4/fpm/conf.d/99-custom.ini`
- **Supervisor Config**: `/etc/supervisor/conf.d/supervisord.conf`
- **Entrypoint**: `/usr/local/bin/start-container`

## 🩺 Healthcheck

The image includes a healthcheck script at `/healthcheck.sh` that checks if Nginx is responding on the `/healthz` endpoint.