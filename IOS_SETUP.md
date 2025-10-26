# iOS Setup Guide

This guide explains how to build and deploy the My Coach Finder iOS app using Codemagic cloud builds.

## What Was Added

### iOS Platform Files
- ✅ iOS platform added via `npx cap add ios`
- ✅ NativeAuthPlugin.swift - Native Google Sign-In for iOS
- ✅ AppDelegate.swift - Updated to handle Google Sign-In callbacks
- ✅ Podfile - Includes Google Sign-In SDK v7.0
- ✅ Info.plist - Configured with Google Sign-In URL scheme
- ✅ capacitor.config.json - iOS configuration added

### Codemagic Configuration
- ✅ codemagic.yaml - Cloud build configuration for iOS

## Building with Codemagic (RECOMMENDED for Linux users)

Since you're on Linux and don't have a Mac, you'll use Codemagic to build your iOS app in the cloud.

### Step 1: Sign Up for Codemagic

1. Go to: https://codemagic.io/
2. Click "Sign up for free"
3. Sign in with your GitHub account
4. Grant Codemagic access to your GitHub repositories

### Step 2: Add Your App

1. In Codemagic dashboard, click **"Add application"**
2. Select **GitHub** as the source
3. Find and select: `HannesFehre/my-coach-finder-2-andruid-1`
4. Codemagic will automatically detect the `codemagic.yaml` file

### Step 3: Set Up App Store Connect API

You need an Apple Developer account ($99/year) and App Store Connect API key:

1. **Get Apple Developer Account:**
   - Go to: https://developer.apple.com/
   - Sign up for Apple Developer Program ($99/year)
   - Wait for approval (usually 1-2 days)

2. **Create App Store Connect API Key:**
   - Go to: https://appstoreconnect.apple.com/
   - Navigate to: **Users and Access** > **Keys** > **App Store Connect API**
   - Click **"+"** to generate new key
   - Give it a name (e.g., "Codemagic Build Key")
   - Role: **App Manager** or **Developer**
   - Download the `.p8` key file (you can only download once!)
   - Note the **Key ID** and **Issuer ID**

3. **Add API Key to Codemagic:**
   - In Codemagic, go to **Teams** > **Integrations**
   - Click **App Store Connect**
   - Upload your `.p8` file
   - Enter your Key ID and Issuer ID
   - Click **Save**

### Step 4: Configure iOS Code Signing

Codemagic can automatically manage your iOS signing certificates:

1. In Codemagic project settings, go to **Distribution**
2. Enable **"Automatic code signing"**
3. Select your App Store Connect API integration
4. Bundle ID: `com.mycoachfinder.app`
5. Codemagic will automatically:
   - Create signing certificates
   - Create provisioning profiles
   - Handle all signing configuration

### Step 5: Start Build

1. In Codemagic dashboard, click **"Start new build"**
2. Select branch: `main`
3. Select workflow: `ios-workflow`
4. Click **"Start new build"**

**Build time:** ~15-20 minutes for first build

### Step 6: Download IPA File

Once the build completes:

1. Go to build details
2. In **Artifacts** section, download the `.ipa` file
3. This is your iOS app!

## Testing the iOS App

### Option 1: TestFlight (RECOMMENDED)

TestFlight allows you to install the app on real iPhones without connecting to a computer.

**From Codemagic:**
1. Enable **"Publish to App Store Connect"** in workflow
2. Codemagic will automatically upload to TestFlight
3. You'll get an email when the build is ready

**On iPhone:**
1. Install **TestFlight** app from App Store
2. Open the email invitation
3. Tap **"Install"**
4. App installs on your iPhone!

### Option 2: Install via Xcode (Requires Mac)

If you have access to a Mac:
```bash
# Connect iPhone via USB
# In Xcode, select your device
# Click Run
```

### Option 3: Simulator (Requires Mac)

```bash
npm run ios
# Opens Xcode
# Select simulator device
# Click Run
```

## Codemagic Pricing

**Free Tier:**
- 500 build minutes/month
- macOS Standard VM (Intel)
- 1 concurrent build

**Pro Tier ($99/month):**
- 3000 build minutes/month
- M1 Mac Mini VMs (faster)
- 3 concurrent builds
- Unlimited apps

**For your use case:**
- Free tier is enough for initial testing
- Each iOS build takes ~15-20 minutes
- Free tier = ~25 builds/month

## Local Development (If you get a Mac later)

If you acquire a Mac in the future:

```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios/App && pod install

# Open Xcode
npm run ios
```

## Google Sign-In on iOS

The iOS app uses the same native Google Sign-In flow as Android:

1. User clicks Google login link on web page
2. JavaScript bridge intercepts the click
3. Native iOS Google Sign-In SDK launches
4. User selects Google account
5. App receives ID token
6. Sends to backend: `POST /auth/google/native?id_token=XXX`
7. Backend returns session token
8. Session saved to iOS Keychain (via Preferences plugin)

**Configuration:**
- Client ID: `353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146`

## Troubleshooting

### Build Fails: "No provisioning profiles found"
- Make sure you've added App Store Connect API key in Codemagic
- Enable "Automatic code signing" in Codemagic settings

### Build Fails: "Pod install failed"
- This should be handled by Codemagic automatically
- If it persists, check Podfile syntax

### Google Sign-In Not Working
- Check that Info.plist has correct URL scheme
- Verify GIDClientID matches your Google OAuth client ID
- Check AppDelegate.swift handles URL callback

### TestFlight Build Not Appearing
- Wait 5-10 minutes after upload (App Store processing)
- Check App Store Connect for processing status
- Ensure you have latest version of TestFlight app

## Next Steps

1. ✅ Sign up for Apple Developer account
2. ✅ Create App Store Connect API key
3. ✅ Sign up for Codemagic
4. ✅ Connect GitHub repository
5. ✅ Add App Store Connect API to Codemagic
6. ✅ Start first iOS build
7. ✅ Download IPA and test via TestFlight

## Resources

- **Codemagic Docs:** https://docs.codemagic.io/
- **Capacitor iOS Docs:** https://capacitorjs.com/docs/ios
- **Google Sign-In iOS:** https://developers.google.com/identity/sign-in/ios
- **TestFlight Guide:** https://developer.apple.com/testflight/

---

**Built with:** Capacitor 6.x + Swift + Google Sign-In SDK 7.0
