# My Coach Finder - iOS App

> Native iOS application for My Coach Finder platform - Connect with your coach, achieve your goals.

**Platform:** iOS 12.0+ | **Technology:** Capacitor 6.x WebView + Native Google Sign-In | **Status:** ✓ In Development

## About My Coach Finder

**My Coach Finder** is Germany's leading platform connecting individuals with qualified coaches across diverse specialties - from life coaching and career planning to health, relationships, mindfulness, and financial guidance.

- **1,000+ Coaches** across various specialties
- **4.8/5 Rating** from 268+ reviews
- **Free for Seekers** - No cost to browse and connect
- **24/7 Support** - Multilingual customer service
- **GDPR Compliant** - German data protection standards

**Website:** https://my-coach-finder.de | **Web App:** https://app.my-coach-finder.com/go

## Quick Start

### Install on Your iOS Device

1. **Build on Codemagic** - CI/CD platform builds the app
2. **Download IPA** - Get the build artifact from Codemagic
3. **Install via TestFlight** (coming soon) or **direct install** during development

### Development Commands

```bash
# Install dependencies
npm install

# Install iOS dependencies
cd ios/App && pod install && cd ../..

# Sync web assets to iOS
npx cap sync ios

# Open in Xcode
npx cap open ios

# Build in Xcode (Cmd + B)
# Or use Codemagic for CI/CD builds
```

## Project Structure

```
appel/
├── README.md                 # This file - Quick start guide
├── PROJECT_STATUS.md         # Project status and build history
├── IOS_BUILD_STATUS.md       # iOS build documentation
├── package.json              # Node.js dependencies
├── capacitor.config.json     # Capacitor configuration
├── codemagic.yaml            # CI/CD configuration
├── www/                      # Web assets (minimal)
│   └── index.html           # Redirects to web app
└── ios/                      # Native iOS project
    └── App/
        ├── App/
        │   ├── NativeAuthPlugin.swift   # Native Google Sign-In
        │   ├── AppDelegate.swift
        │   ├── Info.plist
        │   └── Assets.xcassets/
        │       ├── AppIcon.appiconset/
        │       └── Splash.imageset/
        └── App.xcodeproj/
```

## Key Features

✅ **Native iOS Integration:**
- **Native Google Sign-In** with Google Sign-In SDK
- **WKUserScript** - Automatic JavaScript injection
- **Click Interception** - Detects "Continue with Google" buttons
- **JavaScript Bridge** - Seamless native/web integration
- **JWT Token Management** - Session persistence
- **WebView wrapper** for `https://app.my-coach-finder.com/go`
- **Deep Link Support** - OAuth callback handling
- **Status Bar Hidden** - Full-screen native feel

🔜 **Coming Next:**
- TestFlight beta testing
- App Store submission
- Enhanced session persistence (refresh tokens)
- Platform detection & analytics
- Push notifications with Firebase

## Native OAuth Architecture

### Authentication Flow

```
1. User clicks "Continue with Google" button on web page
   ↓
2. WKUserScript intercepts the click
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
8. App stores JWT in session storage
   ↓
9. App navigates to authenticated page
```

### Key Components

1. **NativeAuthPlugin.swift**
   - WKUserScript auto-injection
   - Google Sign-In SDK integration
   - WebView navigation control

2. **AppDelegate.swift**
   - Google Sign-In configuration
   - App lifecycle management

3. **JavaScript Bridge** (injected via WKUserScript)
   - Intercepts OAuth login clicks
   - Calls native authentication
   - Sends ID token to backend
   - Stores JWT session

### Google OAuth Configuration

**OAuth Client:**
- Client ID: `353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com`
- Bundle ID: `MyCoachFinder`
- URL Scheme: `com.googleusercontent.apps.353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146`

### Click Detection Logic

Intercepts links/buttons for `/auth/google/login` route and triggers native sign-in flow.

## Configuration

### App Identity
- **Bundle ID:** `MyCoachFinder`
- **App Name:** My Coach Finder
- **Version:** 1.1.12 (Build 12)
- **Min iOS:** 12.0
- **Target iOS:** Latest

### Web App URL
```json
{
  "server": {
    "url": "https://app.my-coach-finder.com/go"
  }
}
```

## Build Configuration

### Codemagic CI/CD

#### `ios-development` Workflow
- Instance: Mac mini M1
- Xcode: latest
- Node.js: 20.19.5
- Distribution: Development (Ad Hoc)
- Manual code signing
- Artifacts: .ipa, logs, .app, .dSYM

**Environment Variables (Group: `ios_signing`):**
- `CM_CERTIFICATE` - Base64-encoded .p12 certificate
- `CM_CERTIFICATE_PASSWORD` - Certificate password
- `CM_PROVISIONING_PROFILE` - Base64-encoded .mobileprovision

See `codemagic.yaml` for complete configuration.

## Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Framework | Capacitor | 6.x |
| Runtime | Node.js | 20.19.5 |
| iOS Native | Swift | 5.x |
| Dependency Manager | CocoaPods | Latest |
| CI/CD | Codemagic | Cloud |
| Backend | FastAPI | (Separate Server) |

## Requirements

### Development Environment
- macOS with Xcode (for local builds)
- Node.js 20.x
- CocoaPods
- Apple Developer account (for device testing)

### Environment Variables
For Codemagic builds, credentials are stored in environment variable groups.

## Common Tasks

### Rebuild After Changes
```bash
npx cap sync ios
npx cap open ios
# Build in Xcode
```

### Update Dependencies
```bash
npm install
cd ios/App && pod install && cd ../..
npx cap sync ios
```

### View Build Logs
Check Codemagic dashboard for build logs and artifacts.

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| CocoaPods dependencies | Run `cd ios/App && pod install` |
| Build fails in Xcode | Clean build folder (Cmd + Shift + K) |
| Blank screen | Check internet, verify URL is accessible |
| WebView navigation | Check `allowNavigation` in capacitor.config.json |

### Native OAuth Issues

**Google Sign-In not triggering:**
- Check logs for WKUserScript injection
- Verify button detection logic
- Ensure Google Sign-In SDK is configured

**Backend returns 422 "Field required":**
- ID token must be query parameter, not body
- Correct: `/auth/google/native?id_token=XXX`

## Future Enhancements

### Phase 1: TestFlight
- Beta testing setup
- Feedback collection
- Bug fixes

### Phase 2: App Store
- App Store Connect registration
- Store listing with screenshots
- App review submission
- Production release

### Phase 3: Push Notifications
- Firebase Cloud Messaging integration
- Device token registration
- Notification delivery tracking

### Phase 4: Enhanced Auth
- Refresh token system
- Auto-refresh mechanism
- Biometric authentication

### Phase 5: Analytics
- Platform detection (app vs web)
- User behavior tracking
- Conversion analytics

## Implementation History

This app features **fully native iOS Google Sign-In** using:
- WKUserScript for automatic JavaScript injection
- Google Sign-In iOS SDK
- Custom navigation handling to prevent Safari redirects
- Session persistence
- Full-screen WebView experience

### Build History
- **v1.1.12** - Version bump for icon cache refresh
- **v1.0.11** - Added app icon & splash screen
- **v1.0.10** - WKUserScript + hide status bar
- **v1.0.6** - Added allowNavigation configuration

## Documentation

- **[CICD_SETUP_COMPLETE.md](CICD_SETUP_COMPLETE.md)** - **Complete CI/CD setup guide** (START HERE)
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Project status and roadmap
- **[IOS_BUILD_STATUS.md](IOS_BUILD_STATUS.md)** - Build history
- **[codemagic.yaml](codemagic.yaml)** - CI/CD workflow configuration

## License

Proprietary - My Coach Finder Platform

---

**Built with:** Capacitor ⚡ by Ionic | **Maintained by:** My Coach Finder Team | **Last Updated:** October 27, 2025
