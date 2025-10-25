# My Coach Finder - Android App

> Native Android application for My Coach Finder platform - Connect with your coach, achieve your goals.

**Platform:** Android 5.1+ (API 22+) | **Technology:** Capacitor 6.x WebView + Native Google Sign-In | **Status:** ✓ Production Ready

## About My Coach Finder

**My Coach Finder** is Germany's leading platform connecting individuals with qualified coaches across diverse specialties - from life coaching and career planning to health, relationships, mindfulness, and financial guidance.

- **1,000+ Coaches** across various specialties
- **4.8/5 Rating** from 268+ reviews
- **Free for Seekers** - No cost to browse and connect
- **24/7 Support** - Multilingual customer service
- **GDPR Compliant** - German data protection standards

**Website:** https://my-coach-finder.de | **Web App:** https://app.my-coach-finder.com/go

## Quick Start

### Install on Your Android Device

1. **Enable USB Debugging** on your phone (Settings → Developer Options)
2. **Connect via USB** to your Linux PC
3. **Install the app:**
   ```bash
   cd /home/liz/Desktop/Module/MyCoachFinder/app/andruid
   adb install android/app/build/outputs/apk/debug/app-debug.apk
   ```

### Development Commands

```bash
# Install dependencies
npm install

# Sync web assets to Android
npx cap sync android

# Build APK
cd android && ./gradlew assembleDebug

# Install on connected device
adb install -r app/build/outputs/apk/debug/app-debug.apk

# View logs
adb logcat | grep Capacitor
```

## Project Structure

```
andruid/
├── README.md                 # This file - Quick start guide
├── PROJECT.md                # Full project documentation
├── TESTING.md                # Testing instructions & checklist
├── package.json              # Node.js dependencies
├── capacitor.config.json     # Capacitor configuration
├── www/                      # Web assets (minimal)
│   └── index.html           # Redirects to web app
└── android/                  # Native Android project
    ├── app/build/outputs/apk/
    │   └── debug/
    │       └── app-debug.apk # 🎯 Installable APK (3.6MB)
    └── ...
```

## Key Features

✅ **Native OAuth Complete:**
- **Native Google Sign-In** with Google Play Services SDK
- **Account Picker UI** - Select from device Google accounts
- **Automatic Click Interception** - Detects "Continue with Google" buttons
- **JavaScript Bridge** - Seamless native/web integration
- **JWT Token Management** - 7-day expiry, stored in localStorage
- **WebView wrapper** for `https://app.my-coach-finder.com/go`
- **Deep Link Support** - OAuth callback handling
- **MIUI Compatible** - Works with Xiaomi security restrictions
- **Production Ready** - Fully tested authentication flow

🔜 **Coming Next:**
- Release build with signed APK
- Firebase Cloud Messaging for push notifications
- Enhanced login persistence (refresh tokens)
- Platform detection & analytics
- Custom app icons & splash screens
- Google Play Store submission

## Native OAuth Architecture

### Authentication Flow

```
1. User clicks "Continue with Google" button on web page
   ↓
2. JavaScript bridge intercepts the click
   ↓
3. Native Google Sign-In SDK launches account picker
   ↓
4. User selects Google account
   ↓
5. Plugin receives ID token from Google
   ↓
6. JavaScript sends ID token to backend: POST /auth/google/native?id_token=XXX
   ↓
7. Backend validates token and returns JWT
   ↓
8. App stores JWT in localStorage with key 'token'
   ↓
9. App navigates to authenticated page
```

### Key Components

1. **MainActivity.java**
   - Registers NativeAuthPlugin
   - Injects JavaScript bridge into web pages
   - Configures WebView for OAuth compatibility

2. **NativeAuthPlugin.java**
   - Implements Google Play Services authentication
   - Handles account picker and ID token retrieval
   - Returns results to JavaScript layer

3. **JavaScript Bridge** (injected)
   - Intercepts "Continue with Google" clicks
   - Calls native authentication
   - Sends ID token to backend
   - Stores JWT in localStorage

### Google OAuth Configuration

**Two OAuth Clients Required:**

1. **Web Client** (for ID token validation):
   - Client ID: `353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com`

2. **Android Client** (auto-detected):
   - Package: `com.mycoachfinder.app`
   - SHA-1: `B0:F8:1D:C6:AE:7B:D7:B9:0C:9F:5D:41:E0:A3:1A:DA:39:37:4A:D1`

### Click Detection Logic

Intercepts buttons matching ALL conditions:
- Contains "google" in text, className, id, or data-provider
- Contains sign-in keywords: "sign", "login", "anmeld", "continue", "weiter"
- Does NOT contain logout keywords: "out", "abmeld"
- Is clickable: button, a, div with onclick, or span with onclick

## Configuration

### App Identity
- **Package ID:** `com.mycoachfinder.app`
- **App Name:** My Coach Finder
- **Version:** 1.0 (versionCode 1)
- **Min SDK:** Android 5.1 (API 22)
- **Target SDK:** Android 14 (API 34)

### Web App URL
```json
{
  "server": {
    "url": "https://app.my-coach-finder.com/go"
  }
}
```

## Testing

See [TESTING.md](TESTING.md) for complete testing instructions.

**Quick Test:**
1. Install APK on your Android phone
2. Open "My Coach Finder" app
3. Verify web app loads correctly
4. Test login with OAuth (Google/LinkedIn)
5. Check that login persists after closing app

## Documentation

- **[TESTING.md](TESTING.md)** - Installation guide, testing checklist, debugging tools
- **[package.json](package.json)** - Node.js dependencies and scripts

## Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Capacitor | 6.x |
| Build Tool | Gradle | 8.2.1 |
| Runtime | Node.js | 20.19.5 |
| Java | OpenJDK | 17 |
| Android SDK | Command-line Tools | 34 |
| Database | MySQL | (Backend) |
| Backend | FastAPI | (Separate Server) |

## Requirements

### Development Environment
- Linux (Ubuntu 22.04 or similar)
- Node.js 20.x
- Java 17
- Android SDK (installed in `~/android-sdk`)
- Physical Android device or emulator

### Environment Variables
Add to `~/.bashrc`:
```bash
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```

## File Locations

| File | Purpose | Path |
|------|---------|------|
| **APK** | Installable app | `android/app/build/outputs/apk/debug/app-debug.apk` |
| **Manifest** | App permissions | `android/app/src/main/AndroidManifest.xml` |
| **Config** | Capacitor settings | `capacitor.config.json` |
| **Gradle** | Build configuration | `android/app/build.gradle` |
| **Strings** | App name/labels | `android/app/src/main/res/values/strings.xml` |

## Common Tasks

### Rebuild After Changes
```bash
npx cap sync android
cd android && ./gradlew assembleDebug
```

### Reinstall on Device

**Standard devices:**
```bash
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

**MIUI/Xiaomi devices** (USB install blocked):
```bash
# Push to Downloads folder
adb push android/app/build/outputs/apk/debug/app-debug.apk /sdcard/Download/MyCoachFinder.apk
# Then install from File Manager app
```

### Debug with Chrome DevTools
1. Open app on phone
2. In Chrome, go to `chrome://inspect`
3. Click **Inspect** on your device's WebView

### Clear App Data
```bash
adb shell pm clear com.mycoachfinder.app
```

### View Logs
```bash
adb logcat | grep -E "Capacitor|WebView|ERROR"
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| APK won't install | Uninstall old version: `adb uninstall com.mycoachfinder.app` |
| Device not found | Restart ADB: `adb kill-server && adb start-server` |
| Blank screen | Check internet, verify URL is accessible |
| Build fails | Ensure `android/local.properties` has correct `sdk.dir` path |
| MIUI install blocked | Use `adb push` to Downloads, install from File Manager |

### Native OAuth Issues

**Google Sign-In returns RESULT_CANCELED:**
```bash
# Clear Google Play Services cache
adb shell pm clear com.google.android.gms
```

**Click interceptor not working:**
- Check logs for "Intercepted Google sign-in" message
- Verify button contains "google" and sign-in keyword
- Button must be clickable element (button/a/div/span)

**Backend returns 422 "Field required":**
- ID token must be query parameter, not body
- Correct: `/auth/google/native?id_token=XXX`

**User logged in but redirected to login:**
- Must use localStorage key `'token'` not `'access_token'`

### Debug Logging

View authentication flow:
```bash
adb logcat | grep -E "(NativeAuth|Native Bridge)"
```

Success indicators:
- `[Native Bridge] Injecting native auth`
- `[Native Bridge] Intercepted Google sign-in`
- `NativeAuth: Starting Google Sign-In`
- `NativeAuth: Sign-In successful`
- `[Native Bridge] Backend response status: 200`

## Future Enhancements

### Phase 2: Push Notifications
- Firebase Cloud Messaging integration
- Device token registration endpoint
- Notification delivery tracking
- Open rate analytics

### Phase 3: Enhanced Auth
- Refresh token system (1-year expiry)
- Auto-refresh mechanism
- Biometric authentication

### Phase 4: Analytics
- Platform detection (app vs web)
- User behavior tracking
- Conversion analytics
- A/B testing capabilities

### Phase 5: Play Store
- Google Play Developer account setup
- App signing and optimization
- Store listing with screenshots
- Beta testing program
- Production release

## Implementation History

This app features **fully native Google Sign-In** using Google Play Services SDK with:
- Native account picker UI
- Automatic click interception for "Continue with Google" buttons
- JWT token management (7-day expiry)
- Seamless native/web integration via JavaScript bridge
- Production-tested authentication flow

### OAuth Configuration
- **Web Client ID:** `353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com`
- **Android Client:** Auto-detected via package name `com.mycoachfinder.app`
- **SHA-1 Fingerprint:** `B0:F8:1D:C6:AE:7B:D7:B9:0C:9F:5D:41:E0:A3:1A:DA:39:37:4A:D1`

## License

Proprietary - My Coach Finder Platform

---

**Built with:** Capacitor ⚡ by Ionic | **Maintained by:** My Coach Finder Team | **Last Updated:** October 25, 2025
