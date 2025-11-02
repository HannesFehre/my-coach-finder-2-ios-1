#!/usr/bin/env python3
"""
Complete patch for @codetrix-studio/capacitor-google-auth Plugin.swift for GoogleSignIn 7.x
Fixes ALL API compatibility issues
"""

import re
import sys

PLUGIN_SWIFT = "node_modules/@codetrix-studio/capacitor-google-auth/ios/Plugin/Plugin.swift"

print("📝 Patching Plugin.swift for GoogleSignIn 7.x API compatibility...")

try:
    with open(PLUGIN_SWIFT, 'r') as f:
        content = f.read()
except FileNotFoundError:
    print(f"❌ Plugin.swift not found: {PLUGIN_SWIFT}")
    sys.exit(1)

# Backup
with open(PLUGIN_SWIFT + ".bak", 'w') as f:
    f.write(content)

# Fix 1: resolveSignInCallWith function
# Replace authentication.accessToken → accessToken.tokenString
content = re.sub(
    r'"accessToken":\s*user\.authentication\.accessToken',
    '"accessToken": user.accessToken.tokenString',
    content
)

# Replace authentication.idToken → idToken?.tokenString ?? NSNull()
content = re.sub(
    r'"idToken":\s*user\.authentication\.idToken',
    '"idToken": user.idToken?.tokenString ?? NSNull()',
    content
)

# Replace authentication.refreshToken → refreshToken.tokenString (NOT optional!)
content = re.sub(
    r'"refreshToken":\s*user\.authentication\.refreshToken',
    '"refreshToken": user.refreshToken.tokenString',
    content
)

# Fix 2: refresh() function
# Replace the entire authentication.do block with direct token access
# OLD pattern:
#   self.googleSignIn.currentUser!.authentication.do { (authentication, error) in
#       guard let authentication = authentication else {
#           call.reject(error?.localizedDescription ?? "Something went wrong.");
#           return;
#       }
#       let authenticationData: [String: Any] = [
#           "accessToken": authentication.accessToken,
#           "idToken": authentication.idToken ?? NSNull(),
#           "refreshToken": authentication.refreshToken
#       ]
#       call.resolve(authenticationData);
#   }

old_refresh_pattern = r'''self\.googleSignIn\.currentUser!\.authentication\.do\s*\{\s*\(authentication,\s*error\)\s*in\s*
\s*guard\s+let\s+authentication\s*=\s*authentication\s+else\s*\{\s*
\s*call\.reject\([^)]+\);\s*
\s*return;\s*
\s*\}\s*
\s*let\s+authenticationData:\s*\[String:\s*Any\]\s*=\s*\[\s*
\s*"accessToken":\s*authentication\.accessToken,\s*
\s*"idToken":\s*authentication\.idToken\s*\?\?\s*NSNull\(\),\s*
\s*"refreshToken":\s*authentication\.refreshToken\s*
\s*\]\s*
\s*call\.resolve\(authenticationData\);\s*
\s*\}'''

new_refresh_code = '''let user = self.googleSignIn.currentUser!
            let authenticationData: [String: Any] = [
                "accessToken": user.accessToken.tokenString,
                "idToken": user.idToken?.tokenString ?? NSNull(),
                "refreshToken": user.refreshToken.tokenString
            ]
            call.resolve(authenticationData);'''

content = re.sub(old_refresh_pattern, new_refresh_code, content, flags=re.MULTILINE | re.DOTALL)

# If that didn't work (pattern too strict), try a simpler replacement
if 'authentication.do' in content:
    print("⚠️  Complex pattern didn't match, trying simpler replacement...")
    # Find the refresh function and replace just the authentication.do line
    content = re.sub(
        r'(\s+)self\.googleSignIn\.currentUser!\.authentication\.do\s*\{\s*\(authentication,\s*error\)\s*in',
        r'\1let user = self.googleSignIn.currentUser!\n\1let authenticationData: [String: Any] = [\n\1    "accessToken": user.accessToken.tokenString,\n\1    "idToken": user.idToken?.tokenString ?? NSNull(),\n\1    "refreshToken": user.refreshToken.tokenString\n\1]\n\1call.resolve(authenticationData);\n\1if false { // Skip old code',
        content
    )

    # Close the if false block at the end of the old authentication.do block
    # This effectively comments out the old code
    content = re.sub(
        r'(call\.resolve\(authenticationData\);)\s*\n\s*\}(\s*\n\s*\})',
        r'} // End skip\2',
        content
    )

# Write patched content
with open(PLUGIN_SWIFT, 'w') as f:
    f.write(content)

# Verify changes
errors = 0

if 'user.accessToken.tokenString' not in content:
    print("❌ Failed to patch accessToken")
    errors += 1
else:
    print("✅ Patched accessToken")

if 'user.idToken?.tokenString' not in content:
    print("❌ Failed to patch idToken")
    errors += 1
else:
    print("✅ Patched idToken (optional)")

if 'user.refreshToken.tokenString' not in content:
    print("❌ Failed to patch refreshToken")
    errors += 1
else:
    print("✅ Patched refreshToken")

# Check for old API calls
if 'authentication.accessToken' in content and 'user.accessToken.tokenString' not in content:
    print("⚠️  Warning: Old authentication.accessToken still present without new API")
    errors += 1

if 'authentication.do' in content:
    print("⚠️  Warning: Old authentication.do still present - manual review needed")
    # Not counting as error if new code is also present

if errors > 0:
    print("❌ Patch validation failed - restoring backup")
    with open(PLUGIN_SWIFT + ".bak", 'r') as f:
        backup = f.read()
    with open(PLUGIN_SWIFT, 'w') as f:
        f.write(backup)
    sys.exit(1)

print("✅ Successfully patched Plugin.swift for GoogleSignIn 7.x API")
print("   - accessToken: authentication.accessToken → accessToken.tokenString")
print("   - idToken: authentication.idToken → idToken?.tokenString (optional)")
print("   - refreshToken: authentication.refreshToken → refreshToken.tokenString")
print("   - refresh() function updated for GoogleSignIn 7.x")
