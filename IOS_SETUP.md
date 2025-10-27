# iOS Setup Guide

Complete guide for building and deploying the My Coach Finder iOS app.

---

## 📋 Prerequisites

### Required Accounts
- ✅ **Apple Developer Account** ($99/year) - https://developer.apple.com/
- ✅ **GitHub Account** - Repository hosting
- ✅ **Codemagic Account** (Free tier available) - https://codemagic.io/

### Development Environment
- **For Cloud Builds:** Any OS (Linux, macOS, Windows) - Codemagic handles builds
- **For Local Builds:** macOS with Xcode (optional)

---

## 🚀 Quick Start

### 1. Repository Setup
Project is already configured and pushed to:
```
https://github.com/HannesFehre/my-coach-finder-2-ios-1
```

### 2. Codemagic CI/CD

#### Sign Up & Connect Repository
1. Go to: https://codemagic.io/
2. Sign in with GitHub
3. Grant Codemagic access to your repositories
4. Click **"Add application"**
5. Select repository: `HannesFehre/my-coach-finder-2-ios-1`
6. Codemagic auto-detects `codemagic.yaml` configuration

#### Configure Code Signing

**Manual Code Signing (Current Setup):**

The project uses manual code signing with certificates and provisioning profiles stored as Codemagic environment variables.

**Required Environment Variables:**
Create environment variable group named `ios_signing` with:
- `CM_CERTIFICATE` - Base64-encoded .p12 certificate
- `CM_CERTIFICATE_PASSWORD` - Certificate password
- `CM_PROVISIONING_PROFILE` - Base64-encoded .mobileprovision file

**How to Add Environment Variables:**
1. In Codemagic, go to your app
2. Click **"Environment variables"**
3. Click **"Add group"**
4. Group name: `ios_signing`
5. Add the three variables above
6. Mark them as **Secure** (encrypted)

#### Start Build
1. In Codemagic dashboard
2. Click **"Start new build"**
3. Select workflow: `ios-development`
4. Select branch: `main`
5. Click **"Start new build"**
6. Build takes ~15-20 minutes
7. Download `.ipa` from build artifacts

---

## 🔐 Apple Developer Setup

### Create Bundle Identifier
1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click **"+"** → **"App IDs"** → **"App"**
3. Description: `My Coach Finder`
4. Bundle ID: `com.mycoachfinder.app` (Explicit)
5. Capabilities:
   - ✅ Associated Domains
   - ✅ Push Notifications
6. Click **"Register"**

### Register Test Device (For Development Builds)
1. Get your iPhone UDID:
   - Connect iPhone to Mac → Open Finder → Click device → Click name until UDID shows
   - Or visit: https://udid.tech/ on iPhone in Safari
2. Go to: https://developer.apple.com/account/resources/devices/list
3. Click **"+"**
4. Platform: **iOS**
5. Device Name: `My iPhone` (or any name)
6. Device ID (UDID): Paste UDID
7. Click **"Continue"** → **"Register"**

### Create Certificates & Provisioning Profiles

**For Development (Ad Hoc):**
1. Go to: https://developer.apple.com/account/resources/certificates/list
2. Create **iOS Distribution** certificate
3. Download `.cer` file
4. Convert to `.p12`:
   ```bash
   # On Mac with certificate installed in Keychain
   # Export as .p12 from Keychain Access
   # Or use openssl (advanced)
   ```
5. Create provisioning profile:
   - Go to: https://developer.apple.com/account/resources/profiles/list
   - Click **"+"** → **"Ad Hoc"**
   - Select App ID: `com.mycoachfinder.app`
   - Select certificate (created above)
   - Select devices (registered above)
   - Profile name: `My Coach Finder Development`
   - Download `.mobileprovision` file

6. Encode to Base64 for Codemagic:
   ```bash
   # Certificate
   base64 -i certificate.p12 -o certificate_base64.txt

   # Provisioning profile
   base64 -i profile.mobileprovision -o profile_base64.txt
   ```

7. Add Base64 strings to Codemagic environment variables

---

## 📱 Installing on iPhone

### Method 1: Diawi (Easiest - No Mac Required)
1. Download `.ipa` from Codemagic build artifacts
2. Go to: https://www.diawi.com/
3. Upload `.ipa` file
4. Wait for upload to complete
5. Copy the short link (e.g., `https://i.diawi.com/ABC123`)
6. **On iPhone:**
   - Open link in Safari
   - Tap **"Install"**
   - Go to Settings → General → VPN & Device Management
   - Tap on the certificate → **"Trust"**
   - Return to home screen → App is installed!

### Method 2: Apple Configurator (With Mac)
1. Install **Apple Configurator** from Mac App Store
2. Connect iPhone via USB
3. Drag `.ipa` to device in Apple Configurator
4. App installs automatically

### Method 3: Xcode (With Mac)
1. Open Xcode
2. Window → Devices and Simulators
3. Select your iPhone
4. Drag `.ipa` to "Installed Apps" section

### Method 4: TestFlight (Future - For Beta Testing)
**Requires App Store Connect app registration:**
1. Register app in App Store Connect
2. Use `ios-production` workflow in Codemagic
3. Codemagic auto-uploads to TestFlight
4. Invite beta testers via email
5. Testers install **TestFlight** app
6. Testers receive invite → Install app

---

## 🛠️ Local Development (Optional - Requires Mac)

### Install Dependencies
```bash
# Install Node.js dependencies
npm install

# Install iOS native dependencies
cd ios/App && pod install && cd ../..
```

### Sync Changes
```bash
# After modifying web assets or configuration
npx cap sync ios
```

### Open in Xcode
```bash
# Open iOS project in Xcode
npx cap open ios
```

### Build in Xcode
1. Select device or simulator
2. Press **Cmd + B** to build
3. Press **Cmd + R** to run

---

## 🔧 Project Structure

```
my-coach-finder-2-ios-1/
├── ios/                          # iOS native code
│   └── App/
│       ├── App/
│       │   ├── NativeAuthPlugin.swift    # Google Sign-In
│       │   ├── AppDelegate.swift
│       │   ├── Info.plist
│       │   └── Assets.xcassets/
│       │       ├── AppIcon.appiconset/
│       │       └── Splash.imageset/
│       ├── App.xcodeproj/
│       └── Podfile
├── www/                          # Web assets
│   └── index.html
├── capacitor.config.json         # Capacitor configuration
├── codemagic.yaml                # CI/CD configuration
├── package.json                  # Node dependencies
├── README.md                     # Main documentation
├── PROJECT_STATUS.md             # Project status
├── IOS_BUILD_STATUS.md           # Build history
└── IOS_SETUP.md                  # This file
```

---

## 🔑 Configuration Files

### capacitor.config.json
```json
{
  "appId": "com.mycoachfinder.app",
  "appName": "My Coach Finder",
  "webDir": "www",
  "server": {
    "url": "https://app.my-coach-finder.com/go",
    "cleartext": false,
    "allowNavigation": [
      "app.my-coach-finder.com",
      "*.my-coach-finder.com"
    ]
  },
  "ios": {
    "contentInset": "automatic"
  }
}
```

### Info.plist (Key Settings)
- **Bundle ID:** `com.mycoachfinder.app`
- **Display Name:** My Coach Finder
- **Version:** 1.1.12
- **Build Number:** 12
- **Google Sign-In URL Scheme:** `com.googleusercontent.apps.353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146`

---

## 🎨 Branding Assets

### App Icon
- **Size:** 1024x1024 pixels
- **Format:** PNG with no transparency
- **Location:** `ios/App/App/Assets.xcassets/AppIcon.appiconset/`

### Splash Screen
- **Size:** 2732x2732 pixels (universal)
- **Format:** PNG
- **Location:** `ios/App/App/Assets.xcassets/Splash.imageset/`

---

## 🔐 OAuth Configuration

### Google Sign-In
- **Client ID:** `353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com`
- **Bundle ID:** `com.mycoachfinder.app`
- **URL Scheme:** `com.googleusercontent.apps.353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146`

### Backend Integration
- **Endpoint:** `https://app.my-coach-finder.com/auth/google/native`
- **Method:** POST
- **Parameter:** `id_token` (query parameter)
- **Response:** JWT token for session

---

## 🐛 Troubleshooting

### Build Fails on Codemagic

**"No provisioning profiles found"**
- Verify `CM_PROVISIONING_PROFILE` environment variable is set
- Check Base64 encoding is correct
- Ensure provisioning profile includes your device UDID

**"Certificate not found"**
- Verify `CM_CERTIFICATE` and `CM_CERTIFICATE_PASSWORD` are set
- Check Base64 encoding is correct
- Ensure certificate is iOS Distribution type

**"Pod install failed"**
- Check `Podfile` syntax
- Verify CocoaPods dependencies are compatible
- Check Codemagic build logs for specific error

### Installation Fails on iPhone

**"Unable to Install"**
- Device UDID must be registered in provisioning profile
- Trust certificate in Settings after install
- Check that profile hasn't expired

**"Untrusted Enterprise Developer"**
- Settings → General → VPN & Device Management
- Tap on certificate → Trust

### App Crashes on Launch

**Check Logs:**
```bash
# On Mac with iPhone connected
# Xcode → Window → Devices and Simulators
# Select device → View Device Logs
```

**Common Issues:**
- Missing Google Sign-In configuration
- Invalid Info.plist settings
- WebView URL not accessible

---

## 📊 Codemagic Pricing

### Free Tier
- ✅ 500 build minutes/month
- ✅ macOS Standard VM (Intel)
- ✅ 1 concurrent build
- ✅ Unlimited apps

### Pro Tier ($99/month)
- 3000 build minutes/month
- M1 Mac Mini VMs (faster builds)
- 3 concurrent builds
- Priority support

**Recommendation:**
- Free tier is sufficient for development
- Each build takes ~15-20 minutes
- Free tier = ~25 builds per month

---

## 🔗 Useful Links

### Development
- **Capacitor iOS Docs:** https://capacitorjs.com/docs/ios
- **Swift Documentation:** https://swift.org/documentation/
- **Google Sign-In iOS:** https://developers.google.com/identity/sign-in/ios

### Apple
- **Developer Portal:** https://developer.apple.com/account/
- **App Store Connect:** https://appstoreconnect.apple.com/
- **TestFlight:** https://developer.apple.com/testflight/

### CI/CD
- **Codemagic:** https://codemagic.io/
- **Codemagic Docs:** https://docs.codemagic.io/
- **GitHub:** https://github.com/HannesFehre/my-coach-finder-2-ios-1

---

## 🎯 Next Steps

### For First-Time Setup
1. ✅ Create Apple Developer account
2. ✅ Register Bundle ID in Apple Developer Portal
3. ✅ Register test device (iPhone UDID)
4. ✅ Create certificates and provisioning profiles
5. ✅ Encode to Base64 and add to Codemagic
6. ✅ Trigger first build on Codemagic
7. ✅ Install on iPhone via Diawi

### For Ongoing Development
1. Make changes to code
2. Push to GitHub
3. Trigger Codemagic build
4. Test on device
5. Iterate

### For App Store Release
1. Register app in App Store Connect
2. Create App Store provisioning profile
3. Use `ios-production` workflow
4. Submit to TestFlight for beta testing
5. Submit to App Store for review
6. Public release

---

**Current Status:** iOS app building successfully on Codemagic | Ready for device testing

**Last Updated:** October 27, 2025
