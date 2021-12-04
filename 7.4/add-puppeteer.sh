#!/usr/bin/env bash
set -e

apt-get update
apt install -y chromium
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs

# install wait-for-it
curl -sL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh > /usr/sbin/wait-for-it.sh
chmod +x /usr/sbin/wait-for-it.sh

# cleanup
rm -rf /var/lib/apt/lists/*