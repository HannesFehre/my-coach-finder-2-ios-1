# iOS CI/CD Setup - Complete Guide

**Status:** ✅ **PRODUCTION READY**
**Platform:** Codemagic Cloud
**Last Updated:** November 2, 2025
**Build Status:** Successful - uploading to App Store Connect

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Environment Setup](#environment-setup)
4. [Build Process](#build-process)
5. [Major Issues & Solutions](#major-issues--solutions)
6. [Troubleshooting](#troubleshooting)
7. [Security](#security)

---

## Quick Start

### Trigger a Build

1. Go to https://codemagic.io/apps
2. Select **my-coach-finder-2-ios-1**
3. Click **Start new build**
4. Select workflow: **`ios-production`**
5. Branch: **`main`**

### Expected Results

```
✅ Code signing setup complete
✅ iOS app built successfully
✅ IPA uploaded to App Store Connect
✅ TestFlight ready for testing
```

---

## Prerequisites

### Apple Developer Account
- **Team ID:** 374793446M
- **Bundle ID:** MyCoachFinder
- **App ID:** 6503015097

### Required Certificates
1. **Apple Distribution Certificate** (for App Store)
   - Created on: November 1, 2025
   - Expires: November 1, 2026
   - Format: macOS-compatible SHA1-3DES encryption

2. **App Store Provisioning Profile**
   - Profile UUID: 3ba1c06b-e1b5-4303-8848-7915b63d2168
   - Distribution Type: App Store
   - Bundle ID: MyCoachFinder

### App Store Connect API Key
- **Key ID:** QYXYBNUU85
- **Issuer ID:** d607b8fe-bba2-4c62-b0f3-fc1a424de589
- **Key File:** AuthKey_QYXYBNUU85.p8 (stored securely, NOT in repo)

---

## Environment Setup

### Codemagic Configuration

#### 1. Environment Variable Group: `ios_signing`

Go to: **Codemagic → Environment variables → ios_signing group**

| Variable | Value | Format |
|----------|-------|--------|
| `CM_CERTIFICATE` | *Base64 of ios_distribution_macos_v2.p12* | 4,232 characters, single line |
| `CM_CERTIFICATE_PASSWORD` | `MyCoachFinder2024` | Plain text, no quotes |
| `CM_PROVISIONING_PROFILE` | *Base64 of .mobileprovision* | ~16,288 characters, single line |
| `APP_STORE_CONNECT_PRIVATE_KEY` | *Contents of AuthKey_QYXYBNUU85.p8* | Multi-line, include BEGIN/END |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | `QYXYBNUU85` | Plain text |
| `APP_STORE_CONNECT_ISSUER_ID` | `d607b8fe-bba2-4c62-b0f3-fc1a424de589` | UUID format |

#### 2. Workflow Configuration

File: `codemagic.yaml`

```yaml
workflows:
  ios-production:
    name: iOS App Store Build
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      groups:
        - ios_signing
      vars:
        XCODE_WORKSPACE: "ios/App/App.xcworkspace"
        XCODE_SCHEME: "App"
        BUNDLE_IDENTIFIER: "MyCoachFinder"
        APP_STORE_ID: "6503015097"
      node: 20.19.5
      xcode: latest
      cocoapods: default
```

---

## Build Process

### Step-by-Step

#### 1. Dependency Installation
```bash
npm install
cd ios/App && pod install
```

#### 2. Capacitor Sync
```bash
npx cap sync ios
```

#### 3. Code Signing
- Initialize keychain
- Import distribution certificate (macOS-compatible)
- Install provisioning profile
- Configure Xcode project for manual signing

#### 4. Build Number Increment
```bash
agvtool new-version -all $(($BUILD_NUMBER + 1))
```

#### 5. Build IPA
```bash
xcode-project build-ipa \
  --workspace "$XCODE_WORKSPACE" \
  --scheme "$XCODE_SCHEME"
```

#### 6. Publish to App Store Connect
```bash
app-store-connect publish \
  --path /path/to/App.ipa \
  --key-id $APP_STORE_CONNECT_KEY_IDENTIFIER \
  --issuer-id $APP_STORE_CONNECT_ISSUER_ID
```

---

## Major Issues & Solutions

### 1. Certificate Encryption Compatibility ⭐ **CRITICAL**

**Problem:**
macOS `security` command couldn't import certificates created with Linux OpenSSL using SHA256/AES-256 encryption.

**Error:**
```
security: SecKeychainItemImport: MAC verification failed during PKCS12 import
```

**Root Cause:**
- Certificates were created on Linux with modern OpenSSL defaults
- macOS security tools prefer legacy SHA1-3DES encryption
- Password was correct but encryption format was incompatible

**Solution:**
Created macOS-compatible certificate using SHA1-3DES:

```bash
openssl pkcs12 -export \
  -in ios_distribution_cert.pem \
  -inkey ios_distribution.key \
  -out ios_distribution_macos_v2.p12 \
  -password pass:MyCoachFinder2024 \
  -certpbe PBE-SHA1-3DES \
  -keypbe PBE-SHA1-3DES \
  -macalg sha1
```

**Files:**
- `certificates/ios_distribution_macos_v2.p12` - Certificate file
- `certificates/ios_distribution_macos_v2_base64.txt` - Base64 for Codemagic
- **MD5:** a32cb8ca351f144927f8d9f61bf14321

---

### 2. Provisioning Profile UUID Extraction

**Problem:**
Failed to extract UUID from provisioning profile XML.

**Error:**
```
❌ Failed to extract provisioning profile UUID
```

**Root Cause:**
UUID value is on the line AFTER `<key>UUID</key>` in the XML structure:
```xml
<key>UUID</key>
<string>3ba1c06b-e1b5-4303-8848-7915b63d2168</string>
```

**Solution:**
```bash
PROFILE_UUID=$(grep -A 1 '<key>UUID</key>' profile.plist | \
               grep -o '[a-f0-9]\{8\}-[a-f0-9]\{4\}...' | head -1)
```

---

### 3. App Version Requirements

**Problem:**
Upload failed with version conflict.

**Error:**
```
Invalid Version. The build with version "1.1" can't be imported because
a later version has been closed for new build submissions.
```

**Root Cause:**
- Previously uploaded version: 1.3
- Current build version: 1.1
- App Store requires monotonically increasing versions

**Solution:**
Updated `MARKETING_VERSION` in `ios/App/App.xcodeproj/project.pbxproj`:
```
MARKETING_VERSION = 1.4;
```

---

### 4. Export Compliance Declaration

**Problem:**
Manual encryption declaration required for each submission.

**Solution:**
Added to `Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This declares the app only uses standard iOS encryption, automatically skipping export compliance questions.

---

## Troubleshooting

### Build Fails at Code Signing

**Symptoms:**
```
security: SecKeychainItemImport: MAC verification failed
```

**Checklist:**
1. ✅ Using macOS-compatible certificate (SHA1-3DES)?
2. ✅ Certificate MD5 matches: `a32cb8ca351f144927f8d9f61bf14321`?
3. ✅ Password is exactly: `MyCoachFinder2024` (no exclamation mark)?
4. ✅ Base64 length is 4,232 characters?

**Fix:**
Update `CM_CERTIFICATE` with content from `certificates/ios_distribution_macos_v2_base64.txt`

---

### Upload Fails with Version Error

**Symptoms:**
```
The value for key CFBundleShortVersionString [X.X] must contain a higher version
```

**Fix:**
Update version in `project.pbxproj`:
```bash
# Find current version
grep "MARKETING_VERSION" ios/App/App.xcodeproj/project.pbxproj

# Update to higher version (e.g., 1.5, 2.0, etc.)
# Then commit and push
```

---

### Certificate Expired

**Symptoms:**
```
Certificate expires: 2026-11-01T19:54:22.000+0000
```

**When to Renew:**
30 days before expiration (October 1, 2026)

**How to Renew:**
1. Generate new CSR
2. Create new certificate in Apple Developer Portal
3. Download as .cer file
4. Convert to .p12 with macOS-compatible encryption
5. Update `CM_CERTIFICATE` in Codemagic

---

## Security

### ✅ Protected Files (NOT in Git)

All sensitive files are properly excluded via `.gitignore`:

```
# Certificates
*.p12
*.p8
*.pem
*.key
*.cer
*.mobileprovision
*_base64.txt

# API Keys
CODEMAGIC_API_KEY.txt
AuthKey_*.p8
```

### 🔒 Secure Storage Locations

1. **Certificates** → `certificates/` directory (gitignored)
2. **API Keys** → Environment variables in Codemagic (encrypted)
3. **Private Keys** → `appel_privat/` directory (gitignored)

### ⚠️ Never Commit

- Certificates (.p12, .cer, .pem)
- Private keys (.key, .p8)
- Provisioning profiles (.mobileprovision)
- API keys or passwords
- Base64-encoded credential files

---

## Files Reference

### Critical Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `codemagic.yaml` | CI/CD workflow | Root |
| `capacitor.config.json` | App configuration | Root |
| `Info.plist` | iOS app metadata | `ios/App/App/Info.plist` |
| `project.pbxproj` | Xcode project settings | `ios/App/App.xcodeproj/` |

### Certificate Files (Gitignored)

| File | Purpose | Format |
|------|---------|--------|
| `certificates/ios_distribution_macos_v2.p12` | macOS-compatible cert | Binary |
| `certificates/ios_distribution_macos_v2_base64.txt` | For Codemagic | Base64 |
| `certificates/My_Coach_Finder_App_Store.mobileprovision` | Provisioning profile | Binary |
| `appel_privat/AuthKey_QYXYBNUU85.p8` | App Store Connect API key | PEM |

---

## Success Metrics

### Build Time
- **Average:** 8-12 minutes
- **Code Signing:** ~30 seconds
- **Build:** ~5-7 minutes
- **Upload:** ~2-3 minutes

### Success Indicators

```
✅ Certificate imported successfully
✅ Provisioning profile installed
✅ Code signing setup complete
✅ Build succeeded
✅ Publishing to App Store Connect
✅ Upload succeeded
```

---

## Next Steps

1. **TestFlight Testing**
   - Add internal testers
   - Distribute build
   - Collect feedback

2. **App Store Submission**
   - Complete App Store listing
   - Add screenshots
   - Submit for review

3. **Maintenance**
   - Monitor certificate expiration
   - Keep Xcode/dependencies updated
   - Increment version for each release

---

## Quick Links

- **Codemagic:** https://codemagic.io/apps
- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer:** https://developer.apple.com/account
- **TestFlight:** https://testflight.apple.com

---

## Support

**Issues?** Check:
1. This document's [Troubleshooting](#troubleshooting) section
2. Build logs in Codemagic dashboard
3. Certificate expiration dates

**Build History:** See `PROJECT_STATUS.md` for detailed build log

---

*Last successful build: November 2, 2025*
*Certificate valid until: November 1, 2026*
*Next renewal: October 1, 2026*