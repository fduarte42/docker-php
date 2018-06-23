#!/usr/bin/env bash
set -e

# LOCALES
apt-get update
apt-get install -y locales && rm -rf /var/lib/apt/lists/*

LOCALES="en_EN en_US en_GB fr_FR es_ES pt_PT de_DE"
for L in $LOCALES; do
    localedef -i $L -c -f UTF-8 -A /etc/locale.alias $L.UTF-8
done
