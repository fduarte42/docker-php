#!/usr/bin/env bash
set -e

# add yarn source
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# add chrome source
curl -sL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# update package indexes
apt-get update

# install nodejs
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs
mkdir /var/www/.npm
chown -R www-data:www-data /var/www/.npm
mkdir /var/www/.config
chown -R www-data:www-data /var/www/.config

# install yarn
apt-get install -y yarn
mkdir /var/www/.yarn
chown -R www-data:www-data /var/www/.yarn

# install chrome
apt-get install -y google-chrome-unstable --no-install-recommends

# install wait-for-it
curl -sL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh > /usr/sbin/wait-for-it.sh
chmod +x /usr/sbin/wait-for-it.sh

# cleanup
rm -rf /var/lib/apt/lists/*