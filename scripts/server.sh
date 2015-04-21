#!/bin/bash
./scripts/pub_get.sh
./scripts/setup_config.sh
./scripts/compile_dart2js.sh
cd client
http-server&
cd ../
nodemon server/js/main.js
