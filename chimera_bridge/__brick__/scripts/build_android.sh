#!/bin/bash

# 1. Clean previous builds to ensure fresh linking
echo "🧹 Cleaning Flutter build..."
flutter clean

# 2. Build the AAR (This uses the generated Bridge code & your main.dart implementation)
echo "🏗️  Building Android AAR..."
flutter build aar --no-profile --no-release

# 3. Create the target directory in the node module
mkdir -p android/libs

# 4. Copy the artifacts
# Note: Flutter creates a local Maven repo at build/host/outputs/repo
echo "📦 Moving artifacts to android/libs..."
cp -r build/host/outputs/repo/* android/libs/

echo "✅ Android build complete! The host app can now consume the updated AARs."
