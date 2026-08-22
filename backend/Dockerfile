FROM php:8.4-cli-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libpq-dev \
        libzip-dev \
        libicu-dev \
    && docker-php-ext-install pdo_pgsql pgsql zip intl bcmath pcntl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --prefer-dist --no-interaction \
    && cp .env.example .env \
    && sed -i 's/^DB_HOST=.*/DB_HOST=postgres/' .env \
    && sed -i 's|^FIREBASE_CREDENTIALS=.*|FIREBASE_CREDENTIALS=/var/www/html/storage/app/firebase/itc-events-firebase-adminsdk-fbsvc-1778ccc128.json|' .env \
    && php artisan key:generate --force \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
