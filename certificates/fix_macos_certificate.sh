#!/bin/bash

echo "Fixing certificate for macOS compatibility..."
echo "============================================="

# First extract the certificate and key from existing p12
echo "Step 1: Extracting certificate and key from existing p12..."
openssl pkcs12 -in ios_distribution_simple.p12 -passin pass:MyCoachFinder2024 -out temp_cert.pem -nokeys
openssl pkcs12 -in ios_distribution_simple.p12 -passin pass:MyCoachFinder2024 -out temp_key.pem -nodes -nocerts

# Create new P12 with legacy settings for macOS compatibility
echo ""
echo "Step 2: Creating macOS-compatible certificate with legacy encryption..."

# Method 1: Legacy with specific cipher
openssl pkcs12 -export \
  -legacy \
  -in temp_cert.pem \
  -inkey temp_key.pem \
  -out ios_distribution_macos_v1.p12 \
  -password pass:MyCoachFinder2024 \
  -name "iPhone Distribution"

# Method 2: Without legacy flag but with compatible settings
openssl pkcs12 -export \
  -in temp_cert.pem \
  -inkey temp_key.pem \
  -out ios_distribution_macos_v2.p12 \
  -password pass:MyCoachFinder2024 \
  -certpbe PBE-SHA1-3DES \
  -keypbe PBE-SHA1-3DES \
  -macalg sha1 \
  -name "iPhone Distribution"

# Test both versions
echo ""
echo "Step 3: Testing certificates..."

echo "Testing v1 (legacy):"
if openssl pkcs12 -in ios_distribution_macos_v1.p12 -passin pass:MyCoachFinder2024 -noout 2>/dev/null; then
  echo "✅ v1 works with OpenSSL"
  echo "MD5: $(md5sum ios_distribution_macos_v1.p12 | cut -d' ' -f1)"
  echo "Size: $(ls -lh ios_distribution_macos_v1.p12 | awk '{print $5}')"

  # Create base64
  base64 -w 0 ios_distribution_macos_v1.p12 > ios_distribution_macos_v1_base64.txt
  echo "Base64 length: $(wc -c < ios_distribution_macos_v1_base64.txt)"
else
  echo "❌ v1 failed"
fi

echo ""
echo "Testing v2 (SHA1-3DES):"
if openssl pkcs12 -in ios_distribution_macos_v2.p12 -passin pass:MyCoachFinder2024 -noout 2>/dev/null; then
  echo "✅ v2 works with OpenSSL"
  echo "MD5: $(md5sum ios_distribution_macos_v2.p12 | cut -d' ' -f1)"
  echo "Size: $(ls -lh ios_distribution_macos_v2.p12 | awk '{print $5}')"

  # Create base64
  base64 -w 0 ios_distribution_macos_v2.p12 > ios_distribution_macos_v2_base64.txt
  echo "Base64 length: $(wc -c < ios_distribution_macos_v2_base64.txt)"
else
  echo "❌ v2 failed"
fi

# Clean up temp files
rm -f temp_cert.pem temp_key.pem

echo ""
echo "============================================="
echo "COMPLETE!"
echo ""
echo "Two versions created:"
echo "1. ios_distribution_macos_v1_base64.txt (legacy encryption)"
echo "2. ios_distribution_macos_v2_base64.txt (SHA1-3DES encryption)"
echo ""
echo "Try v2 first (SHA1-3DES) as it's most compatible with macOS"
echo "Password for both: MyCoachFinder2024"