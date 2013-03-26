#!/bin/bash
cd client
http-server&
cd ../
nodemon server/js/main.js
