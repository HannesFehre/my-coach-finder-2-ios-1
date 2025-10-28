# APP CRASH FIX - CocoaPods Dependencies Not Installed

**Problem:** App crashes when clicking Google button
**Cause:** CocoaPods dependencies (GoogleSignIn SDK) not installed
**Platform:** You're on Linux, can't run `pod install` locally

---

## WHY IT CRASHES

The community plugin needs the GoogleSignIn SDK, which is installed via CocoaPods:

```
Plugin needs: GoogleSignIn SDK
Located in: Podfile
Status: ❌ Not installed (no Pods directory found)
```

When you click the button, the plugin tries to call GoogleSignIn methods, but the SDK isn't there → **CRASH**

---

## SOLUTION OPTIONS

### OPTION 1: Build on Mac (Recommended)

If you have access to a Mac:

```bash
# 1. Copy your project to Mac
# 2. Navigate to ios/App directory
cd ios/App

# 3. Install CocoaPods if needed
sudo gem install cocoapods

# 4. Install dependencies
pod install

# 5. Open workspace (NOT .xcodeproj)
open App.xcworkspace

# 6. Build and run in Xcode
# Click ▶ button in Xcode
```

---

### OPTION 2: Use Codemagic CI/CD

Codemagic automatically runs `pod install`:

1. **Push your code to GitHub** (already done ✅)
2. **Trigger Codemagic build**
3. **Download TestFlight build**
4. **Test on device**

Codemagic will:
- Run `pod install` automatically
- Install GoogleSignIn SDK
- Build working IPA
- Upload to TestFlight

---

### OPTION 3: Use GitHub Codespaces or Remote Mac

If you don't have a Mac:

**GitHub Codespaces:**
1. Open your repository on GitHub
2. Click "Code" → "Codespaces" → "Create codespace"
3. In the codespace terminal:
   ```bash
   cd ios/App
   pod install
   ```

**Remote Mac Service:**
- MacStadium
- MacinCloud
- AWS EC2 Mac instances

---

## WHAT NEEDS TO HAPPEN

Before the app will work, this MUST happen:

```bash
cd /path/to/app/ios/App
pod install
```

This command:
1. Reads `Podfile`
2. Downloads GoogleSignIn SDK (version 6.2.4)
3. Downloads other dependencies
4. Creates `App.xcworkspace`
5. Links everything together

**Result:**
```
ios/App/
├── Podfile ✅
├── Podfile.lock ✅ (created)
├── Pods/ ✅ (created with GoogleSignIn SDK)
└── App.xcworkspace ✅ (use this, not .xcodeproj)
```

---

## VERIFICATION

After `pod install` runs successfully, check:

```bash
# 1. Podfile.lock should exist
ls ios/App/Podfile.lock

# 2. Pods directory should exist
ls ios/App/Pods

# 3. GoogleSignIn should be installed
grep "GoogleSignIn" ios/App/Podfile.lock

# 4. Workspace should exist
ls ios/App/App.xcworkspace
```

---

## FOR CODEMAGIC BUILD

Your `codemagic.yaml` should have this step (check if it exists):

```yaml
- name: Install CocoaPods dependencies
  script: |
    cd ios/App
    pod install
```

If it's missing, add it. Otherwise Codemagic handles it automatically.

---

## EXPECTED CODEMAGIC OUTPUT

When Codemagic runs `pod install`, you'll see:

```
Analyzing dependencies
Downloading dependencies
Installing GoogleSignIn (6.2.4)
Installing CodetrixStudioCapacitorGoogleAuth (0.0.1)
Installing GTMAppAuth (2.0.0)
Installing GTMSessionFetcher (3.1.0)
Generating Pods project
Integrating client project

[✓] Pod installation complete!
```

---

## TROUBLESHOOTING

### "pod: command not found"

On Mac:
```bash
sudo gem install cocoapods
```

On Linux:
- ❌ CocoaPods doesn't work on Linux
- ✅ Use Codemagic or Mac instead

### "Your Podfile has had smart quotes sanitized"

Not a problem, just a warning. Ignore it.

### "Unable to find a specification for GoogleSignIn"

```bash
pod repo update
pod install
```

### Build still crashes after pod install

1. Clean build folder in Xcode: `Product → Clean Build Folder`
2. Close Xcode
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen workspace (not .xcodeproj)
5. Build again

---

## CURRENT SITUATION

**Your Status:**
- ✅ Plugin added to package.json
- ✅ Podfile configured correctly
- ✅ capacitor.config.json setup
- ✅ Info.plist correct
- ❌ **CocoaPods not installed** ← YOU ARE HERE
- ⏸️ Can't build until pods installed

**Next Action:**
- If on Mac: Run `pod install`
- If on Linux: Push to Codemagic and let it build

---

## QUICK CHECK: DO YOU HAVE A MAC?

### If YES (You have Mac access):
```bash
# On your Mac:
cd ios/App
pod install
open App.xcworkspace
# Build in Xcode
```

### If NO (Linux only):
```bash
# Push to GitHub
git push origin main

# Go to Codemagic
# Trigger build
# Download TestFlight build when ready
# Test on iPhone
```

---

## AFTER POD INSTALL

Once `pod install` completes:

1. **Open the WORKSPACE** (not .xcodeproj):
   ```bash
   open ios/App/App.xcworkspace
   ```

2. **Build in Xcode:**
   - Select device or simulator
   - Click ▶ Run
   - Wait for build

3. **Test:**
   - App should launch
   - Click Google button
   - **Should NOT crash** ✅
   - Native Google picker appears

---

## CRASH LOGS (If Still Crashes)

If it still crashes after pod install, get crash logs:

**On Mac (Xcode):**
1. Window → Devices and Simulators
2. Select your device
3. Click "View Device Logs"
4. Find crash log
5. Look for "Exception Type" and "Exception Message"

**Share these lines:**
```
Exception Type: ...
Exception Message: ...
Thread 0 Crashed: ...
```

---

## SUMMARY

**Problem:** CocoaPods dependencies not installed
**Why:** You're on Linux (can't run pod install)
**Solutions:**
1. Use Mac to run `pod install`
2. Use Codemagic (runs pod install automatically)
3. Use remote Mac service

**After pod install:** App won't crash, button will work!

---

**Status:** Blocked by platform (Linux can't run CocoaPods)
**Recommended:** Let Codemagic build handle it
**Alternative:** Get Mac access to test locally
