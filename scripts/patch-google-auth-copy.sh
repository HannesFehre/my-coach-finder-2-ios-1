#!/bin/bash
# Foolproof patch: Just copy the pre-patched Plugin.swift file
# No complex regex, no sed/perl/awk - just a simple file copy!

PLUGIN_SWIFT="node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"
PATCHED_FILE="patches/Plugin.swift.patched"

echo "📝 Applying pre-patched Plugin.swift..."

if [ ! -f "$PATCHED_FILE" ]; then
    echo "❌ ERROR: Pre-patched file not found: $PATCHED_FILE"
    exit 1
fi

if [ ! -f "$PLUGIN_SWIFT" ]; then
    echo "❌ ERROR: Target Plugin.swift not found: $PLUGIN_SWIFT"
    exit 1
fi

echo "✅ Found pre-patched file: $PATCHED_FILE"
echo "✅ Found target file: $PLUGIN_SWIFT"

# Backup original
cp "$PLUGIN_SWIFT" "$PLUGIN_SWIFT.original.bak"
echo "✅ Backed up original file"

# Copy pre-patched version
cp "$PATCHED_FILE" "$PLUGIN_SWIFT"
echo "✅ Copied pre-patched file"

# Verify patches
echo ""
echo "Verifying patches..."

errors=0

# Check DispatchQueue patch
if grep -q "DispatchQueue.main.async {" "$PLUGIN_SWIFT"; then
    echo "❌ ERROR: Still has old DispatchQueue trailing closure syntax!"
    errors=1
elif grep -q "DispatchQueue.main.async({" "$PLUGIN_SWIFT"; then
    count=$(grep -c "DispatchQueue.main.async({" "$PLUGIN_SWIFT")
    echo "✅ DispatchQueue patch verified ($count occurrences)"
else
    echo "⚠️  Warning: No DispatchQueue.main.async found"
fi

# Check GoogleSignIn 7.x API patch
if grep -q "user.accessToken.tokenString" "$PLUGIN_SWIFT"; then
    echo "✅ GoogleSignIn 7.x API patch verified"
else
    echo "❌ ERROR: GoogleSignIn 7.x API patch missing!"
    errors=1
fi

# Check that serverAuthCode was removed
if grep -q "user.serverAuthCode" "$PLUGIN_SWIFT"; then
    echo "❌ ERROR: serverAuthCode still present (should be removed)!"
    errors=1
else
    echo "✅ serverAuthCode removed (correct for GoogleSignIn 7.x)"
fi

if [ $errors -gt 0 ]; then
    echo ""
    echo "❌ Patch verification failed - restoring original"
    cp "$PLUGIN_SWIFT.original.bak" "$PLUGIN_SWIFT"
    exit 1
fi

echo ""
echo "✅ All patches verified successfully!"
echo "✅ Plugin.swift is now fully patched for GoogleSignIn 7.x + Swift 5 strict concurrency"

exit 0
