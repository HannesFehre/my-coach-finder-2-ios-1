# Testing My Coach Finder Android App

## APK Location

Your debug APK has been successfully built:
```
/home/liz/Desktop/Module/MyCoachFinder/app/andruid/android/app/build/outputs/apk/debug/app-debug.apk
```

**File Size:** 3.6MB

## Prerequisites for Testing

### 1. Enable USB Debugging on Your Android Device

1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times to enable Developer Mode
3. Go back to **Settings** → **Developer Options**
4. Enable **USB Debugging**
5. Enable **Install via USB** (if available)

### 2. Connect Your Device

1. Connect your Android phone to your Linux PC via USB cable
2. On your phone, you'll see a prompt "Allow USB debugging?" → Tap **Allow**
3. Check the checkbox "Always allow from this computer" for convenience

### 3. Verify Connection

Run this command to verify your device is connected:
```bash
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
adb devices
```

You should see output like:
```
List of devices attached
ABC123XYZ    device
```

If you see "unauthorized", check your phone for the USB debugging prompt and tap "Allow".

## Installation Methods

### Method 1: Install via ADB (Recommended)

From the project root directory:

```bash
# Navigate to the project
cd /home/liz/Desktop/Module/MyCoachFinder/app/andruid

# Install the APK on your connected device
adb install -r android/app/build/outputs/apk/debug/app-debug.apk
```

The `-r` flag allows reinstalling if the app is already installed.

Expected output:
```
Performing Streamed Install
Success
```

### Method 2: Copy APK to Phone

If ADB doesn't work, you can manually copy the APK:

1. Copy the APK to your phone:
```bash
adb push android/app/build/outputs/apk/debug/app-debug.apk /sdcard/Download/
```

2. On your phone:
   - Open **Files** or **My Files** app
   - Navigate to **Downloads**
   - Tap on `app-debug.apk`
   - Tap **Install** (you may need to enable "Install from Unknown Sources")

### Method 3: Email/Cloud Transfer

1. Email the APK to yourself or upload to Google Drive/Dropbox
2. Download on your phone
3. Open the downloaded APK file
4. Tap **Install**

## Testing Checklist

Once installed, test the following features:

### ✓ Basic Functionality
- [ ] App launches without crashing
- [ ] Splash screen appears briefly
- [ ] Web app loads at `https://app.my-coach-finder.com/go`
- [ ] No blank white screen
- [ ] No error messages

### ✓ Navigation
- [ ] All links work correctly
- [ ] Back button navigates within the web app
- [ ] Pages load without errors
- [ ] Images and assets load properly

### ✓ Authentication
- [ ] Can access login page
- [ ] Google OAuth login works
- [ ] LinkedIn OAuth login works
- [ ] Apple Sign-In works (if applicable)
- [ ] Login session persists after closing app
- [ ] Logout works correctly

### ✓ Performance
- [ ] Pages load reasonably fast
- [ ] Scrolling is smooth
- [ ] No lag or stuttering
- [ ] App doesn't consume excessive battery

### ✓ Permissions
- [ ] Internet access works
- [ ] Network state detection works
- [ ] No unnecessary permission requests

### ✓ Data Storage
- [ ] Login state persists after app restart
- [ ] User preferences are saved
- [ ] localStorage works correctly
- [ ] Cookies are maintained

## Common Issues & Solutions

### Issue: "Installation blocked"
**Solution:** Enable "Install from Unknown Sources"
1. Settings → Security → Unknown Sources → Enable
2. Or tap "Settings" on the install prompt to enable for this install only

### Issue: "App not installed"
**Solution:** Uninstall the old version first
```bash
adb uninstall com.mycoachfinder.app
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

### Issue: "Device unauthorized"
**Solution:**
1. Revoke USB debugging authorizations on your phone
2. Disconnect and reconnect the USB cable
3. Accept the USB debugging prompt again

### Issue: "ADB device not found"
**Solution:**
```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

### Issue: App shows blank white screen
**Solution:**
1. Check internet connection on your phone
2. Try accessing `https://app.my-coach-finder.com/go` in Chrome to verify it loads
3. Check logcat for errors:
```bash
adb logcat | grep -i "capacitor\|webview\|error"
```

### Issue: OAuth login doesn't work
**Possible causes:**
- OAuth redirect URIs not configured for the app
- WebView blocking third-party cookies
- Need to whitelist the app package ID in OAuth provider settings

**Debug:**
```bash
# View real-time logs
adb logcat | grep -i "oauth\|auth"
```

## Debugging Tools

### View Real-time Logs
```bash
# All logs
adb logcat

# Filter for Capacitor
adb logcat | grep Capacitor

# Filter for errors
adb logcat | grep -E "ERROR|FATAL"

# Clear and view fresh logs
adb logcat -c && adb logcat
```

### Take Screenshot
```bash
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ~/Desktop/
```

### Screen Recording
```bash
# Record for 60 seconds
adb shell screenrecord /sdcard/demo.mp4 --time-limit 60

# Stop recording (Ctrl+C)

# Download the video
adb pull /sdcard/demo.mp4 ~/Desktop/
```

### Clear App Data
If you need to reset the app completely:
```bash
adb shell pm clear com.mycoachfinder.app
```

### Uninstall App
```bash
adb uninstall com.mycoachfinder.app
```

## Performance Monitoring

### Check App Memory Usage
```bash
adb shell dumpsys meminfo com.mycoachfinder.app
```

### Check Battery Usage
```bash
adb shell dumpsys batterystats com.mycoachfinder.app
```

### Monitor Network Activity
```bash
adb shell dumpsys netstats com.mycoachfinder.app
```

## Remote Debugging

You can debug the WebView content using Chrome DevTools:

1. On your phone, open the My Coach Finder app
2. On your PC, open Google Chrome
3. Navigate to `chrome://inspect`
4. You should see your device and the WebView listed
5. Click **Inspect** to open DevTools
6. Now you can:
   - Inspect HTML/CSS
   - Debug JavaScript
   - View console logs
   - Monitor network requests
   - Test responsive design

## Rebuilding After Changes

If you make changes to the web assets or configuration:

```bash
# Sync changes to Android
npx cap sync android

# Rebuild APK
cd android && ./gradlew assembleDebug

# Reinstall on device
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Building Release APK (For Play Store)

When ready for production:

```bash
# Build release APK (unsigned)
cd android && ./gradlew assembleRelease

# Output location:
# android/app/build/outputs/apk/release/app-release-unsigned.apk
```

For Play Store, you'll need to:
1. Generate a signing key
2. Sign the APK
3. Optimize with `zipalign`
4. Or use Android App Bundle (AAB) format

See Google Play documentation for detailed release instructions.

## Next Steps After Testing

Once basic testing is complete:

1. **Firebase Push Notifications** - Set up FCM for push notifications
2. **Enhanced Login** - Implement refresh tokens for longer sessions
3. **Platform Analytics** - Add tracking to differentiate app vs web users
4. **App Icon & Splash** - Create custom branding assets
5. **Play Store Listing** - Prepare screenshots, description, and metadata
6. **Beta Testing** - Share with select users via Google Play Console
7. **Production Release** - Submit to Google Play Store

## Testing Report Template

After testing, document your findings:

```markdown
# Test Report - My Coach Finder Android App
**Date:** [Date]
**Tester:** [Your Name]
**Device:** [Phone Model]
**Android Version:** [e.g., Android 13]
**APK Version:** 1.0 (debug)

## Test Results

### ✅ Passed
- List features that work correctly

### ❌ Failed
- List issues found with details

### ⚠️ Issues
- List minor issues or improvements needed

## Screenshots
[Attach screenshots]

## Recommendations
[Your suggestions for improvements]
```

## Support

If you encounter issues:
1. Check the logs using `adb logcat`
2. Verify internet connectivity
3. Ensure the web app URL is accessible
4. Review AndroidManifest.xml permissions
5. Check Capacitor configuration in `capacitor.config.json`

For Capacitor-specific issues, see: https://capacitorjs.com/docs/debugging

---

**Last Updated:** October 25, 2025
**APK Built:** ✓ Successfully
**Status:** Ready for testing on physical device
