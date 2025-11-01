# 🔧 FIX: Certificate Password Issue in Codemagic

## Problem
Build fails with: `MAC verification failed during PKCS12 import (wrong password?)`

## Root Cause
The `CM_CERTIFICATE_PASSWORD` environment variable in Codemagic either:
1. Contains the wrong password
2. Has extra spaces/characters
3. Has special characters not properly escaped

## ✅ SOLUTION

### Step 1: Update Environment Variable in Codemagic

1. **Go to:** https://codemagic.io/apps
2. **Select:** my-coach-finder-2-ios-1
3. **Go to:** Environment variables → `ios_signing` group
4. **Find:** `CM_CERTIFICATE_PASSWORD`
5. **DELETE the old value completely**
6. **Type exactly (no quotes, no spaces):**
   ```
   MyCoachFinder2024!
   ```
7. **Important:**
   - NO spaces before or after
   - NO quotes around it
   - Type it manually, don't copy-paste (to avoid hidden characters)
8. **Check:** "Secure" checkbox ✓
9. **Save** the environment group

### Step 2: Double-Check All 6 Variables

Ensure these are all correct in the `ios_signing` group:

| Variable | Value | Notes |
|----------|-------|-------|
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | `QYXYBNUU85` | No spaces |
| `APP_STORE_CONNECT_PRIVATE_KEY` | (full .p8 key with BEGIN/END lines) | Exactly as shown |
| `APP_STORE_CONNECT_ISSUER_ID` | `d607b8fe-bba2-4c62-b0f3-fc1a424de589` | No spaces |
| `CM_CERTIFICATE` | (4,272 characters) | Base64 string, no line breaks |
| `CM_CERTIFICATE_PASSWORD` | `MyCoachFinder2024!` | **EXACTLY this, no quotes** |
| `CM_PROVISIONING_PROFILE` | (16,288 characters) | Base64 string, no line breaks |

### Step 3: Alternative - Add Debug Script

If password still fails, update the workflow to debug:

```yaml
- name: Debug certificate password
  script: |
    echo "Password length: ${#CM_CERTIFICATE_PASSWORD}"
    echo "First char: ${CM_CERTIFICATE_PASSWORD:0:1}"
    echo "Last char: ${CM_CERTIFICATE_PASSWORD: -1}"
    # Test certificate with password
    echo "$CM_CERTIFICATE" | base64 --decode > /tmp/test.p12
    openssl pkcs12 -info -in /tmp/test.p12 -passin pass:"$CM_CERTIFICATE_PASSWORD" -noout
```

---

## 🔍 Common Causes of This Error

1. **Copy-paste issues:**
   - Hidden characters (zero-width spaces)
   - Smart quotes instead of regular quotes
   - Line breaks in the middle

2. **Special character handling:**
   - The `!` in the password might need escaping
   - Some systems interpret `!` as history expansion

3. **Encoding issues:**
   - Certificate base64 has line breaks
   - Certificate was corrupted during encoding

---

## ✅ Quick Fix if Nothing Else Works

Create a NEW certificate with a simpler password:

```bash
# Create new p12 with simple password (no special chars)
cd /home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates
openssl pkcs12 -export -out ios_distribution_simple.p12 \
  -inkey ios_distribution.key -in ios_distribution.pem \
  -password pass:MyCoachFinder2024

# Encode to base64
base64 -w 0 ios_distribution_simple.p12 > ios_distribution_simple_base64.txt

# Use password: MyCoachFinder2024 (no exclamation mark)
```

Then update Codemagic with:
- New base64 certificate
- New password: `MyCoachFinder2024` (no `!`)

---

## 📋 Verification Commands

After updating Codemagic, these should work in the build:

```bash
# Should succeed with correct password
security import /tmp/distribution.p12 \
  -k "$KEYCHAIN_PATH" \
  -P "$CM_CERTIFICATE_PASSWORD" \
  -T /usr/bin/codesign
```

---

Created: November 1, 2025