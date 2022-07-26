#!/bin/sh

# Create the .env file if it does not exist.
echo "---Created .env file ---"
if [[ ! -f "./.env" ]] && [[ -f "./.env.example" ]];
then
cp ./.env.example ./.env
fi

echo "---Starting services using docker-compose---"
docker-compose up -d --build --remove-orphans --force-recreate

echo "---Installing dependencies---"
# docker-compose exec php composer config -g http-basic.repo.magento.com ${key} ${secret}
docker-compose exec php composer install --ignore-platform-reqs --no-interaction --working-dir=/var/www/src
