#!/bin/bash
# Fix DispatchQueue.main.async trailing closure syntax for Swift 5 strict concurrency

PLUGIN_SWIFT="node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"

echo "📝 Fixing DispatchQueue.main.async trailing closure syntax..."

if [ ! -f "$PLUGIN_SWIFT" ]; then
    echo "❌ Plugin.swift not found: $PLUGIN_SWIFT"
    exit 1
fi

# Backup
cp "$PLUGIN_SWIFT" "$PLUGIN_SWIFT.dispatch.bak"

# Use perl for multi-line replacements (sed can't handle this reliably)

# Fix signIn function
perl -i -0pe 's/(func signIn\([^)]*\)\s*\{\s*signInCall = call;\s*)DispatchQueue\.main\.async\s*\{((?:(?!^\s*func\s).)*self\.resolveSignInCallWith\(user: user!\);(?:(?!^\s*func\s).)*\}\s*\}\s*)\}/\1DispatchQueue.main.async(execute: {\2})/ms' "$PLUGIN_SWIFT"

# Fix refresh function
perl -i -0pe 's/(func refresh\([^)]*\)\s*\{\s*)DispatchQueue\.main\.async\s*\{((?:(?!^\s*func\s).)*call\.resolve\(authenticationData\);(?:(?!^\s*func\s).)*)\}/\1DispatchQueue.main.async(execute: {\2})/ms' "$PLUGIN_SWIFT"

# Fix signOut function
perl -i -0pe 's/(func signOut\([^)]*\)\s*\{\s*)DispatchQueue\.main\.async\s*\{((?:(?!^\s*func\s).)*self\.googleSignIn\.signOut\(\);(?:(?!^\s*func\s).)*)\}/\1DispatchQueue.main.async(execute: {\2})/ms' "$PLUGIN_SWIFT"

# Verify
if grep -q "DispatchQueue.main.async {" "$PLUGIN_SWIFT"; then
    echo "❌ ERROR: Still has old trailing closure syntax!"
    cp "$PLUGIN_SWIFT.dispatch.bak" "$PLUGIN_SWIFT"
    exit 1
fi

if grep -q "DispatchQueue.main.async(execute: {" "$PLUGIN_SWIFT"; then
    echo "✅ Successfully fixed DispatchQueue.main.async syntax"
    exit 0
else
    echo "⚠️  Warning: No DispatchQueue.main.async found"
    exit 0
fi
