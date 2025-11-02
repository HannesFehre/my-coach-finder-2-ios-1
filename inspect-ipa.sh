#!/bin/bash

# Script to inspect IPA file contents on Linux
# This verifies the OSParameterPlugin.swift was compiled into the app

if [ -z "$1" ]; then
    echo "Usage: ./inspect-ipa.sh path/to/App.ipa"
    echo ""
    echo "This script extracts and inspects an IPA file to verify:"
    echo "  1. OSParameterPlugin is compiled"
    echo "  2. Bundle version is correct"
    echo "  3. Info.plist is configured"
    exit 1
fi

IPA_FILE="$1"

if [ ! -f "$IPA_FILE" ]; then
    echo "❌ Error: File not found: $IPA_FILE"
    exit 1
fi

echo "=================================================="
echo "📦 IPA Inspector"
echo "=================================================="
echo ""

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "📂 Extracting IPA to: $TEMP_DIR"

# IPA files are just ZIP archives
unzip -q "$IPA_FILE" -d "$TEMP_DIR"

# Find the .app directory
APP_DIR=$(find "$TEMP_DIR" -name "*.app" | head -1)

if [ -z "$APP_DIR" ]; then
    echo "❌ Error: No .app directory found in IPA"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "✅ Found app: $(basename "$APP_DIR")"
echo ""

# Check for compiled plugin
echo "=================================================="
echo "1️⃣ Checking for OSParameterPlugin"
echo "=================================================="
MAIN_BINARY="$APP_DIR/$(basename "$APP_DIR" .app)"

if [ -f "$MAIN_BINARY" ]; then
    if strings "$MAIN_BINARY" | grep -q "OSParameter"; then
        echo "✅ OSParameterPlugin found in binary"
        echo ""
        echo "Plugin references:"
        strings "$MAIN_BINARY" | grep "OSParameter" | head -10
    else
        echo "❌ OSParameterPlugin NOT found in binary"
    fi
else
    echo "⚠️  Could not find main binary"
fi

echo ""
echo "=================================================="
echo "2️⃣ Bundle Information"
echo "=================================================="

# Extract Info.plist
INFO_PLIST="$APP_DIR/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    # Try to read plist (binary format)
    if command -v plutil > /dev/null 2>&1; then
        plutil -p "$INFO_PLIST" | grep -E "(CFBundleShortVersionString|CFBundleVersion|CFBundleIdentifier|CFBundleDisplayName)"
    else
        echo "ℹ️  Install 'plutil' to read plist files"
        echo "Contents (raw binary - may not be readable):"
        cat "$INFO_PLIST" | strings | grep -E "(MyCoachFinder|1\.[0-9])" | head -10
    fi
else
    echo "❌ Info.plist not found"
fi

echo ""
echo "=================================================="
echo "3️⃣ Google Sign-In Configuration"
echo "=================================================="

if [ -f "$INFO_PLIST" ]; then
    if strings "$INFO_PLIST" | grep -q "GIDClientID"; then
        echo "✅ Google Sign-In configured"
        strings "$INFO_PLIST" | grep -E "(GIDClientID|GIDServerClientID|googleusercontent)" | head -5
    else
        echo "❌ Google Sign-In NOT configured"
    fi
fi

echo ""
echo "=================================================="
echo "4️⃣ File Structure"
echo "=================================================="
echo "Main directories in app:"
ls -la "$APP_DIR" | grep "^d" | awk '{print $NF}'

echo ""
echo "Frameworks:"
if [ -d "$APP_DIR/Frameworks" ]; then
    ls "$APP_DIR/Frameworks" | grep -E "\.framework$" | head -10
else
    echo "No Frameworks directory"
fi

echo ""
echo "=================================================="
echo "5️⃣ Plugins & Capacitor"
echo "=================================================="

# Check for Capacitor
if strings "$MAIN_BINARY" | grep -q "Capacitor"; then
    echo "✅ Capacitor found"
else
    echo "❌ Capacitor NOT found"
fi

# Check for Google Auth plugin
if strings "$MAIN_BINARY" | grep -q "GoogleAuth"; then
    echo "✅ Google Auth plugin found"
else
    echo "❌ Google Auth plugin NOT found"
fi

echo ""
echo "=================================================="
echo "✅ Inspection Complete"
echo "=================================================="
echo ""
echo "To cleanup temp files:"
echo "  rm -rf $TEMP_DIR"
echo ""
