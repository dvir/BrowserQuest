#!/bin/bash
./compile_dart2js.sh
cd client
http-server&
cd ../
nodemon server/js/main.js
