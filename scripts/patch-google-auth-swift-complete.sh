#!/bin/bash
# Complete patch for @codetrix-studio/capacitor-google-auth Plugin.swift for GoogleSignIn 7.x
# Fixes ALL API compatibility issues

PLUGIN_SWIFT="node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"

if [ ! -f "$PLUGIN_SWIFT" ]; then
  echo "❌ Plugin.swift not found: $PLUGIN_SWIFT"
  exit 1
fi

echo "📝 Patching Plugin.swift for GoogleSignIn 7.x API compatibility..."

# Create backup
cp "$PLUGIN_SWIFT" "$PLUGIN_SWIFT.bak"

# Fix 1: resolveSignInCallWith function - Update token access
# accessToken is NOT optional in 7.x
sed -i.tmp 's/"accessToken": user\.authentication\.accessToken/"accessToken": user.accessToken.tokenString/g' "$PLUGIN_SWIFT"

# idToken is OPTIONAL in 7.x
sed -i.tmp 's/"idToken": user\.authentication\.idToken/"idToken": user.idToken?.tokenString ?? NSNull()/g' "$PLUGIN_SWIFT"

# refreshToken is NOT optional in 7.x (GIDToken, not GIDToken?)
sed -i.tmp 's/"refreshToken": user\.authentication\.refreshToken/"refreshToken": user.refreshToken.tokenString/g' "$PLUGIN_SWIFT"

# Fix 2: refresh() function - Replace authentication.do with direct token access
# This is more complex - need to replace the entire authentication.do block

# First, let's create a sed script that handles the refresh function
# OLD:
#   self.googleSignIn.currentUser!.authentication.do { (authentication, error) in
#       guard let authentication = authentication else { ... }
#       let authenticationData: [String: Any] = [
#           "accessToken": authentication.accessToken,
#           "idToken": authentication.idToken ?? NSNull(),
#           "refreshToken": authentication.refreshToken
#       ]
#       call.resolve(authenticationData);
#   }
# NEW:
#   let user = self.googleSignIn.currentUser!
#   let authenticationData: [String: Any] = [
#       "accessToken": user.accessToken.tokenString,
#       "idToken": user.idToken?.tokenString ?? NSNull(),
#       "refreshToken": user.refreshToken.tokenString
#   ]
#   call.resolve(authenticationData);

# Replace the refresh function's authentication.do call
cat > /tmp/refresh_fix.sed << 'SEDEOF'
/self\.googleSignIn\.currentUser!\.authentication\.do/,/^            }$/ {
    /self\.googleSignIn\.currentUser!\.authentication\.do/ {
        c\
            let user = self.googleSignIn.currentUser!\
            let authenticationData: [String: Any] = [\
                "accessToken": user.accessToken.tokenString,\
                "idToken": user.idToken?.tokenString ?? NSNull(),\
                "refreshToken": user.refreshToken.tokenString\
            ]\
            call.resolve(authenticationData);
        d
    }
    /guard let authentication/d
    /call\.reject.*Something went wrong/d
    /return;/d
    /let authenticationData/d
    /"accessToken":/d
    /"idToken":/d
    /"refreshToken":/d
    /\]/d
    /call\.resolve(authenticationData)/d
}
SEDEOF

sed -i.tmp -f /tmp/refresh_fix.sed "$PLUGIN_SWIFT"

# Clean up temp files
rm -f "$PLUGIN_SWIFT.tmp" /tmp/refresh_fix.sed

# Verify the changes
ERRORS=0

if ! grep -q "user.accessToken.tokenString" "$PLUGIN_SWIFT"; then
  echo "❌ Failed to patch accessToken"
  ERRORS=$((ERRORS + 1))
fi

if ! grep -q "user.idToken?.tokenString" "$PLUGIN_SWIFT"; then
  echo "❌ Failed to patch idToken"
  ERRORS=$((ERRORS + 1))
fi

if ! grep -q "user.refreshToken.tokenString" "$PLUGIN_SWIFT"; then
  echo "❌ Failed to patch refreshToken"
  ERRORS=$((ERRORS + 1))
fi

# Check that old API calls are gone
if grep -q "authentication\.accessToken" "$PLUGIN_SWIFT"; then
  echo "⚠️  Warning: Old authentication.accessToken still present"
fi

if grep -q "authentication\.do" "$PLUGIN_SWIFT"; then
  echo "⚠️  Warning: Old authentication.do still present"
fi

if [ $ERRORS -gt 0 ]; then
  echo "❌ Patch failed - restoring backup"
  mv "$PLUGIN_SWIFT.bak" "$PLUGIN_SWIFT"
  exit 1
fi

# Clean up backup
rm -f "$PLUGIN_SWIFT.bak"

echo "✅ Successfully patched Plugin.swift for GoogleSignIn 7.x API"
echo "   - accessToken: user.authentication.accessToken → user.accessToken.tokenString"
echo "   - idToken: user.authentication.idToken → user.idToken?.tokenString (optional)"
echo "   - refreshToken: user.authentication.refreshToken → user.refreshToken.tokenString"
echo "   - refresh() function: authentication.do → direct token access"
echo "✅ Plugin.swift patch completed successfully"
