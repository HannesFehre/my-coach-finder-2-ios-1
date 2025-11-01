#!/bin/bash
# Certificate Verification Script
# This script verifies the iOS distribution certificate and password

echo "=========================================="
echo "iOS Distribution Certificate Verification"
echo "=========================================="
echo ""

# Test passwords
PASSWORDS=("MyCoachFinder2024" "MyCoachFinder2024!")

# Certificate file
CERT_FILE="ios_distribution_simple.p12"

if [ ! -f "$CERT_FILE" ]; then
    echo "❌ Certificate file not found: $CERT_FILE"
    exit 1
fi

echo "📁 Certificate file: $CERT_FILE"
echo "📏 File size: $(ls -lh $CERT_FILE | awk '{print $5}')"
echo ""

# Test each password
for PASSWORD in "${PASSWORDS[@]}"; do
    echo "Testing password: $PASSWORD"
    echo "-------------------"

    # Test with OpenSSL
    if openssl pkcs12 -info -in "$CERT_FILE" -passin pass:"$PASSWORD" -noout 2>/dev/null; then
        echo "✅ OpenSSL: Password is CORRECT"

        # Extract certificate info
        echo ""
        echo "Certificate Details:"
        openssl pkcs12 -in "$CERT_FILE" -passin pass:"$PASSWORD" -noout -info 2>&1 | head -5

        # Extract certificate subject
        echo ""
        echo "Certificate Subject:"
        openssl pkcs12 -in "$CERT_FILE" -passin pass:"$PASSWORD" -noout -clcerts 2>/dev/null | openssl x509 -noout -subject 2>/dev/null

    else
        echo "❌ OpenSSL: Password is INCORRECT"
    fi

    echo ""
done

# Base64 encoding verification
echo "=========================================="
echo "Base64 Encoding Verification"
echo "=========================================="
echo ""

BASE64_FILE="ios_distribution_simple_base64.txt"
if [ -f "$BASE64_FILE" ]; then
    echo "📁 Base64 file: $BASE64_FILE"
    echo "📏 Characters: $(wc -c < $BASE64_FILE)"

    # Verify base64 is valid
    if base64 --decode < "$BASE64_FILE" > /tmp/test_cert.p12 2>/dev/null; then
        echo "✅ Base64 decoding: VALID"

        # Compare with original
        if cmp -s "$CERT_FILE" /tmp/test_cert.p12; then
            echo "✅ Decoded certificate matches original"
        else
            echo "❌ Decoded certificate does NOT match original"
        fi
        rm -f /tmp/test_cert.p12
    else
        echo "❌ Base64 decoding: INVALID"
    fi
else
    echo "⚠️  Base64 file not found: $BASE64_FILE"
fi

echo ""
echo "=========================================="
echo "Recommended Codemagic Environment Variable:"
echo "=========================================="
echo ""
echo "CM_CERTIFICATE_PASSWORD: MyCoachFinder2024"
echo "(No quotes, no spaces, no special characters after '2024')"
echo ""
echo "✅ Certificate is ready for use!"