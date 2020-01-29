#!/bin/bash

rm -f /usr/src/app/tmp/pids/server.pid /usr/src/app/log/*.log
bundle exec rake db:migrate

rails server -b 0.0.0.0 &
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:3000/api/active)" != "200" ]]; do sleep 5; done'
/usr/src/app/script/init.rb
sleep infinity