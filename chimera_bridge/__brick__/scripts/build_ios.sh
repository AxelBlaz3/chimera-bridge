#!/bin/bash

# Ensure we are in the project root
if [ -d "../lib" ] && [ -f "../pubspec.yaml" ]; then
    cd ..
fi

echo "🧹 Cleaning Flutter build..."
rm -rf ios/Frameworks
flutter clean

echo "🏗️  Building iOS Frameworks..."
flutter build ios-framework --output=ios/Frameworks

echo "✅ iOS build complete!"