#!/bin/bash
# iOS Remote Debugging Setup Script

echo "=================================================="
echo "iOS Remote Debugging on Linux"
echo "=================================================="
echo ""

# Check for connected devices
echo "1. Checking for connected iOS devices..."
DEVICE_ID=$(idevice_id -l 2>/dev/null)

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iOS device detected!"
    echo ""
    echo "Please:"
    echo "  1. Connect your iPhone via USB"
    echo "  2. Unlock your iPhone"
    echo "  3. Trust this computer when prompted"
    echo "  4. Run this script again"
    echo ""
    exit 1
fi

echo "✅ iOS device connected: $DEVICE_ID"
echo ""

# Get device info
echo "2. Getting device information..."
DEVICE_NAME=$(ideviceinfo -k DeviceName 2>/dev/null)
PRODUCT_VERSION=$(ideviceinfo -k ProductVersion 2>/dev/null)
PRODUCT_TYPE=$(ideviceinfo -k ProductType 2>/dev/null)

echo "   Device Name: $DEVICE_NAME"
echo "   iOS Version: $PRODUCT_VERSION"
echo "   Model: $PRODUCT_TYPE"
echo ""

# Check if Web Inspector is enabled
echo "3. Checking Web Inspector..."
echo "   Make sure Web Inspector is enabled on your iPhone:"
echo "   Settings → Safari → Advanced → Web Inspector = ON"
echo ""

# Start the adapter
echo "4. Starting RemoteDebug iOS WebKit Adapter..."
echo ""
echo "=================================================="
echo "IMPORTANT INSTRUCTIONS:"
echo "=================================================="
echo ""
echo "After the adapter starts:"
echo ""
echo "1. Open your MyCoachFinder app on iPhone"
echo "2. Navigate to any page (login, register, etc.)"
echo "3. Open Chrome on this Linux machine"
echo "4. Go to: chrome://inspect"
echo "5. You should see your iPhone listed"
echo "6. Click 'inspect' to open DevTools"
echo ""
echo "To test os=apple parameter:"
echo "  - Navigate to /auth/login or /auth/register"
echo "  - Check Console for [OSParameter] logs"
echo "  - Run: console.log(window.location.href)"
echo "  - Verify URL contains '?os=apple'"
echo ""
echo "=================================================="
echo ""
echo "Starting adapter... (Press Ctrl+C to stop)"
echo ""

# Start the adapter (port 9000 by default)
remotedebug_ios_webkit_adapter --port=9000
