#!/bin/bash

rm -f /usr/src/app/tmp/pids/server.pid
rails server -b 0.0.0.0