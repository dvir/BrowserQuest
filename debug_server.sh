#!/bin/bash
cd client
http-server&
cd ../
nodemon --debug server/js/main.js
