#!/bin/bash
# Patch @codetrix-studio/capacitor-google-auth to use GoogleSignIn 7.1 instead of 6.2.4
# This is required for Apple Privacy Manifest support (ITMS-91061)

PODSPEC_FILE="node_modules/@codetrix-studio/capacitor-google-auth/CodetrixStudioCapacitorGoogleAuth.podspec"

if [ ! -f "$PODSPEC_FILE" ]; then
  echo "❌ Podspec file not found: $PODSPEC_FILE"
  exit 1
fi

echo "📝 Patching GoogleSignIn dependency in $PODSPEC_FILE..."

# Replace GoogleSignIn 6.2.4 with 7.1
sed -i.bak "s/GoogleSignIn', '~> 6\.2\.4'/GoogleSignIn', '~> 7.1'/g" "$PODSPEC_FILE"

# Update deployment target from 12.0 to 14.0
sed -i.bak "s/deployment_target  = '12\.0'/deployment_target  = '14.0'/g" "$PODSPEC_FILE"

# Verify the changes
if grep -q "GoogleSignIn', '~> 7.1'" "$PODSPEC_FILE"; then
  echo "✅ Successfully patched GoogleSignIn dependency to 7.1"
else
  echo "❌ Failed to patch GoogleSignIn dependency"
  exit 1
fi

if grep -q "deployment_target  = '14.0'" "$PODSPEC_FILE"; then
  echo "✅ Successfully updated deployment target to 14.0"
else
  echo "❌ Failed to update deployment target"
  exit 1
fi

echo "✅ Podspec patch completed successfully"
