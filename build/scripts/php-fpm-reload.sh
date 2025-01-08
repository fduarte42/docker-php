#!/bin/bash

PID=$(cat /var/run/php/php*-fpm.pid)
kill -SIGUSR2 $PID && echo "PHP FPM reloaded"
