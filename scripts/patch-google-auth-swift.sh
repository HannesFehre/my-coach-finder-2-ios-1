#!/bin/bash
# Patch @codetrix-studio/capacitor-google-auth Plugin.swift for GoogleSignIn 7.x API
# GoogleSignIn 7.x changed the authentication API structure

PLUGIN_SWIFT="node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"

if [ ! -f "$PLUGIN_SWIFT" ]; then
  echo "❌ Plugin.swift not found: $PLUGIN_SWIFT"
  exit 1
fi

echo "📝 Patching Plugin.swift for GoogleSignIn 7.x API compatibility..."

# Use Python for complex multiline replacement
if command -v python3 &> /dev/null; then
  python3 scripts/patch-google-auth-swift.py
  exit $?
fi

# Fallback: Simple bash sed (only fixes resolveSignInCallWith, not refresh)
echo "⚠️  Python not available, using basic bash patch (may not fix all issues)"

# Create backup
cp "$PLUGIN_SWIFT" "$PLUGIN_SWIFT.bak"

# GoogleSignIn 7.x API changes in resolveSignInCallWith function:
# OLD: user.authentication.accessToken → NEW: user.accessToken.tokenString
# OLD: user.authentication.idToken → NEW: user.idToken?.tokenString
# OLD: user.authentication.refreshToken → NEW: user.refreshToken.tokenString (NOT optional!)

# Patch accessToken
sed -i.tmp 's/user\.authentication\.accessToken/user.accessToken.tokenString/g' "$PLUGIN_SWIFT"

# Patch idToken (make it optional)
sed -i.tmp 's/"idToken": user\.authentication\.idToken/"idToken": user.idToken?.tokenString ?? NSNull()/g' "$PLUGIN_SWIFT"

# Patch refreshToken (NOT optional in GoogleSignIn 7.x)
sed -i.tmp 's/"refreshToken": user\.authentication\.refreshToken/"refreshToken": user.refreshToken.tokenString/g' "$PLUGIN_SWIFT"

# Clean up temp files
rm -f "$PLUGIN_SWIFT.tmp"

# Verify the changes
if grep -q "user.accessToken.tokenString" "$PLUGIN_SWIFT" && \
   grep -q "user.idToken?.tokenString" "$PLUGIN_SWIFT" && \
   grep -q "user.refreshToken.tokenString" "$PLUGIN_SWIFT"; then
  echo "✅ Successfully patched Plugin.swift for GoogleSignIn 7.x API"
  echo "   - accessToken: user.authentication.accessToken → user.accessToken.tokenString"
  echo "   - idToken: user.authentication.idToken → user.idToken?.tokenString"
  echo "   - refreshToken: user.authentication.refreshToken → user.refreshToken.tokenString"
  echo "⚠️  Note: refresh() function may still need manual fixes"
else
  echo "❌ Failed to patch Plugin.swift"
  mv "$PLUGIN_SWIFT.bak" "$PLUGIN_SWIFT"
  exit 1
fi

# Clean up backup
rm -f "$PLUGIN_SWIFT.bak"

echo "✅ Plugin.swift patch completed successfully"
