# iOS Certificates Directory

**⚠️ IMPORTANT: All files in this directory are gitignored for security**

This directory contains iOS distribution certificates, provisioning profiles, and related files required for code signing.

## Current Active Files

### For Codemagic (App Store Builds)

| File | Purpose | Usage |
|------|---------|-------|
| `ios_distribution_macos_v2.p12` | macOS-compatible distribution certificate | Binary file |
| `ios_distribution_macos_v2_base64.txt` | Base64 encoded certificate | Copy to Codemagic `CM_CERTIFICATE` |
| `My_Coach_Finder_App_Store.mobileprovision` | App Store provisioning profile | Binary file |
| `appstore_profile_base64.txt` | Base64 encoded provisioning profile | Copy to Codemagic `CM_PROVISIONING_PROFILE` |

### Certificate Details

**Certificate:**
- Type: Apple Distribution (App Store)
- Encryption: SHA1-3DES (macOS compatible)
- Password: `MyCoachFinder2024`
- Created: November 1, 2025
- Expires: November 1, 2026
- MD5: `a32cb8ca351f144927f8d9f61bf14321`

**Provisioning Profile:**
- UUID: `3ba1c06b-e1b5-4303-8848-7915b63d2168`
- Type: App Store
- Bundle ID: `MyCoachFinder`

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `fix_macos_certificate.sh` | Creates macOS-compatible certificates from PEM files |
| `verify_certificate.sh` | Verifies certificate and shows details |
| `verify.sh` | Quick certificate verification |

## Security Notes

### ✅ Protected
- All certificate files (.p12, .cer, .pem, .key)
- All provisioning profiles (.mobileprovision)
- All base64 encoded files (*_base64.txt)
- **These files are in .gitignore and will NEVER be committed**

### 🔒 Sensitive Information
Never share these files or commit them to version control:
- `.p12` files (contain private keys)
- `.key` files (private keys)
- `.p8` files (API keys)
- Base64 encoded versions of above

## Certificate Renewal Process

When certificate expires (November 1, 2026):

1. **Generate new CSR**
   ```bash
   openssl req -new -newkey rsa:2048 -nodes \
     -keyout ios_distribution_NEW.key \
     -out ios_distribution_NEW.csr
   ```

2. **Create certificate in Apple Developer Portal**
   - Upload CSR
   - Download as .cer file

3. **Convert to macOS-compatible .p12**
   ```bash
   ./fix_macos_certificate.sh
   ```

4. **Update Codemagic**
   - Upload new base64 to `CM_CERTIFICATE`
   - Update password if changed

## File Locations

**In Repository (gitignored):**
- `certificates/` - All certificate files
- `appel_privat/` - API keys and private credentials

**In Codemagic:**
- Environment Variables → `ios_signing` group
- Encrypted and secure

## Quick Reference

### Extract Certificate Info
```bash
openssl pkcs12 -in ios_distribution_macos_v2.p12 \
  -passin pass:MyCoachFinder2024 -noout -info
```

### Verify Provisioning Profile
```bash
security cms -D -i My_Coach_Finder_App_Store.mobileprovision
```

### Check Certificate Expiration
```bash
openssl pkcs12 -in ios_distribution_macos_v2.p12 \
  -passin pass:MyCoachFinder2024 -nokeys | \
  openssl x509 -noout -enddate
```

---

**For complete CI/CD setup instructions, see:** `../CICD_SETUP_COMPLETE.md`