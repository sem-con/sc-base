#!/bin/bash

rm -f /usr/src/app/tmp/pids/server.pid /usr/src/app/log/*.log
rails server -b 0.0.0.0 &
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:3000/api/log)" != "200" ]]; do sleep 5; done'
/usr/src/app/script/init.rb "$1"
sleep infinity