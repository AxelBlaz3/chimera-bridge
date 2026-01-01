#!/bin/bash

# 1. Clean
echo "🧹 Cleaning Flutter build..."
rm -rf ios/Frameworks
flutter clean

# 2. Build the Frameworks
echo "🏗️  Building iOS Frameworks..."
flutter build ios-framework --output=ios/Frameworks

echo "✅ iOS build complete! Run 'pod install' in the host app's ios folder."
