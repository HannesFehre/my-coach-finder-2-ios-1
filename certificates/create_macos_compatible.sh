#!/bin/bash

echo "Creating macOS-compatible certificate..."
echo "======================================="

# Create a new P12 with legacy algorithms for macOS compatibility
# Using -legacy flag and RC2-40 cipher which macOS handles better

echo "Method 1: Using legacy encryption (most compatible)..."
openssl pkcs12 -export \
  -legacy \
  -in ios_distribution_cert.pem \
  -inkey ios_distribution.key \
  -out ios_distribution_macos.p12 \
  -password pass:MyCoachFinder2024 \
  -name "iPhone Distribution"

echo "Created: ios_distribution_macos.p12"

# Create base64 version
base64 -w 0 ios_distribution_macos.p12 > ios_distribution_macos_base64.txt
echo "Created: ios_distribution_macos_base64.txt"

# Verify the new certificate
echo ""
echo "Verifying new certificate..."
openssl pkcs12 -in ios_distribution_macos.p12 -passin pass:MyCoachFinder2024 -noout
if [ $? -eq 0 ]; then
  echo "✅ Certificate verified successfully with password: MyCoachFinder2024"
else
  echo "❌ Certificate verification failed"
fi

# Get file info
echo ""
echo "Certificate details:"
echo "Size: $(ls -lh ios_distribution_macos.p12 | awk '{print $5}')"
echo "MD5: $(md5sum ios_distribution_macos.p12 | cut -d' ' -f1)"
echo "Base64 length: $(wc -c < ios_distribution_macos_base64.txt)"

echo ""
echo "======================================="
echo "IMPORTANT: Use ios_distribution_macos_base64.txt for CM_CERTIFICATE in Codemagic"
echo "Password remains: MyCoachFinder2024"