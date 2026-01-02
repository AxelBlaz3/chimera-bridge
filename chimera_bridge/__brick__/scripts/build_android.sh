#!/bin/bash

# Ensure we are in the project root
# (If script is run as ./scripts/build.sh, we are already in root. 
# If run from inside scripts/, we move up.)
if [ -d "../lib" ] && [ -f "../pubspec.yaml" ]; then
    cd ..
fi

echo "🧹 Cleaning Flutter build..."
flutter clean

echo "🏗️  Building Android AAR..."
flutter build aar --no-profile --no-release

mkdir -p android/libs
echo "📦 Moving artifacts to android/libs..."
cp -r build/host/outputs/repo/* android/libs/

echo "✅ Android build complete!"