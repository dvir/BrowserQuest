#!/bin/bash
echo "Compiling Dart to JS..."
time dart2js -c client/dart/home.dart -o client/dart/home.dart.js
