#!/bin/bash
if [ ! -f client/dart/config.dart ]; then
  echo "Creating local config.dart..."
  cp client/dart/config.dart-default client/dart/config.dart
fi
