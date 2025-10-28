# Working Build Configuration

**Last Successful Build:** October 28, 2025
**Status:** ✅ Building Successfully on Codemagic

---

## Build Configuration Summary

### Bundle Configuration
- **Bundle ID:** `MyCoachFinder`
- **App Name:** My Coach Finder
- **Version:** 1.1.12 (Build 12)
- **Team:** Hannes Fehre (374793446M)

### Code Signing Setup
- **Method:** Manual Code Signing
- **Certificate:** iOS Development Certificate (.p12)
- **Provisioning Profile:** MyCoachFinder_Development.mobileprovision
- **Distribution Type:** Development
- **Profile Expiration:** October 28, 2026

---

## Codemagic Environment Variables

All variables are stored in the **`app_store_credentials`** group:

### Required for Code Signing
1. **`CM_CERTIFICATE`**
   - Base64-encoded .p12 certificate
   - Source: `ios_development_NEW_base64.txt`
   - Size: 4,373 characters
   - Mark as: **Secure**

2. **`CM_CERTIFICATE_PASSWORD`**
   - Password for the .p12 certificate
   - Mark as: **Secure**

3. **`CM_PROVISIONING_PROFILE`**
   - Base64-encoded .mobileprovision file
   - Source: `profile_NEW_base64.txt`
   - Size: 16,872 characters
   - Mark as: **Secure**

### Required for App Store Connect
4. **`APP_STORE_CONNECT_PRIVATE_KEY`**
   - For publishing to TestFlight/App Store
   - Mark as: **Secure**

5. **`APP_STORE_CONNECT_KEY_IDENTIFIER`**
   - API Key ID
   - Mark as: **Secure**

6. **`APP_STORE_CONNECT_ISSUER_ID`**
   - Issuer ID
   - Mark as: **Secure**

---

## Build Process

### Workflow: ios-development

```yaml
1. Install npm dependencies
2. Install CocoaPods dependencies
3. Sync Capacitor assets to iOS
4. Set up keychain
5. Add certificates to keychain (automatic)
6. Set up code signing settings (automatic)
7. Build iOS app
```

### Build Command
```bash
xcode-project build-ipa \
  --workspace "ios/App/App.xcworkspace" \
  --scheme "App" \
  --archive-flags="-destination 'generic/platform=iOS'"
```

---

## Xcode Project Configuration

### File: `ios/App/App.xcodeproj/project.pbxproj`

**Key Settings:**
- `CODE_SIGN_STYLE = Manual`
- `DEVELOPMENT_TEAM = 374793446M`
- `PRODUCT_BUNDLE_IDENTIFIER = MyCoachFinder`
- `MARKETING_VERSION = 1.1`
- `CURRENT_PROJECT_VERSION = 12`

---

## Integration Configuration

### File: `codemagic.yaml`

**Integration:**
```yaml
integrations:
  app_store_connect: codemagic_api_key
```

**Environment:**
```yaml
environment:
  ios_signing:
    distribution_type: development
    bundle_identifier: MyCoachFinder
  vars:
    XCODE_WORKSPACE: "ios/App/App.xcworkspace"
    XCODE_SCHEME: "App"
    BUNDLE_IDENTIFIER: "MyCoachFinder"
```

---

## Important Files

### Certificate Files (Not in Git - Gitignored)
- `ios_development_NEW.p12` - Development certificate
- `ios_development_NEW_base64.txt` - Base64 encoded certificate
- `MyCoachFinder_Development.mobileprovision` - Provisioning profile
- `profile_NEW_base64.txt` - Base64 encoded profile

### Configuration Files (In Git)
- `codemagic.yaml` - CI/CD configuration
- `capacitor.config.json` - Capacitor configuration
- `ios/App/App.xcodeproj/project.pbxproj` - Xcode project settings
- `package.json` - Node dependencies

---

## Troubleshooting

### If Build Fails with "Unable to decode"
- Certificate or profile base64 is incomplete in environment variables
- Re-copy FULL content from base64 files (all characters)
- Certificate should be ~4,373 characters
- Profile should be ~16,872 characters

### If Build Fails with "Provisioning profile required"
- Check `CODE_SIGN_STYLE = Manual` in Xcode project
- Check `DEVELOPMENT_TEAM = 374793446M` is set
- Verify certificate and profile are correctly installed

### If Certificate Import Fails
- Verify `CM_CERTIFICATE_PASSWORD` is correct
- Check certificate file is valid .p12 format
- Ensure certificate matches the team ID

---

## Build Artifacts

### Output Files
- `build/ios/ipa/*.ipa` - Installable iOS app
- `/tmp/xcodebuild_logs/*.log` - Build logs
- `$HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.app` - App bundle
- `$HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.dSYM` - Debug symbols

---

## Next Steps

### For Development Testing
1. Download `.ipa` from Codemagic build artifacts
2. Install via TestFlight or direct installation
3. Test on physical devices

### For Production Release
1. Update provisioning profile to App Store distribution
2. Change `distribution_type` to `app_store` in codemagic.yaml
3. Create ios-production workflow
4. Submit to App Store Connect

---

**Document Version:** 1.0
**Last Updated:** October 28, 2025
**Status:** Production Ready ✅
