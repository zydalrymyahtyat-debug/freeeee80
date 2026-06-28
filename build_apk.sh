#!/bin/bash

# This script builds small-sized APKs locally.
# It uses --split-per-abi to create a separate APK for each architecture (armeabi-v7a, arm64-v8a, x86_64).
# It also obfuscates the code to reduce size and protect it.

echo "Cleaning previous builds..."
flutter clean
flutter pub get

echo "Building small APKs..."
flutter build apk --split-per-abi --obfuscate --split-debug-info=app-obfuscation-info

echo "Build complete. APKs are located at:"
ls -lh build/app/outputs/flutter-apk/app-*-release.apk
