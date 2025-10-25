#!/bin/bash

# My Coach Finder Android - Build Script
# This script builds the Android APK and optionally installs it on a connected device

set -e  # Exit on error

echo "🚀 Building My Coach Finder Android App..."
echo ""

# Set Android SDK path
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Navigate to android directory
cd "$(dirname "$0")/android"

# Build the APK
echo "📦 Building debug APK..."
./gradlew assembleDebug

echo ""
echo "✅ Build successful!"
echo ""
echo "📍 APK Location:"
echo "   $(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo ""

# Get APK size
APK_SIZE=$(du -h app/build/outputs/apk/debug/app-debug.apk | cut -f1)
echo "📊 APK Size: $APK_SIZE"
echo ""

# Check if device is connected
if adb devices | grep -q "device$"; then
    echo "📱 Android device detected!"
    echo ""
    read -p "Install on device now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📲 Installing app on device..."
        adb install -r app/build/outputs/apk/debug/app-debug.apk
        echo ""
        echo "✅ App installed successfully!"
        echo ""
        echo "💡 To view logs, run:"
        echo "   adb logcat | grep Capacitor"
    fi
else
    echo "ℹ️  No Android device connected via USB."
    echo ""
    echo "To install manually:"
    echo "1. Connect your Android device via USB"
    echo "2. Enable USB debugging on your phone"
    echo "3. Run: adb install -r app/build/outputs/apk/debug/app-debug.apk"
fi

echo ""
echo "🎉 Done!"
