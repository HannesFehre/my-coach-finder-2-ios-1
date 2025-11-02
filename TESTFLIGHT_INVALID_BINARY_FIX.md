# 🔴 TestFlight Invalid Binary - How to Fix

**Date**: 2025-11-02
**Issue**: Builds 37 & 38 (v1.4) showing "Invalid Binary" in TestFlight
**Solution**: Build v1.5 with privacy manifest fixes

---

## ❌ Why Builds 37 & 38 Are Invalid

Apple rejected these builds due to **missing Apple Privacy Manifests** for Google SDKs.

This is the ITMS-91061 error we fixed in commit `9b774b3`:

```
ITMS-91061: Missing privacy manifest
Your app uses Google Sign-In SDK that requires an Apple Privacy Manifest.
```

**v1.4 builds 37/38**: ❌ No privacy manifests → Invalid Binary
**v1.5 (next build)**: ✅ Privacy manifests included → Will be VALID

---

## ✅ What's Fixed in v1.5

Version 1.5 has TWO critical fixes:

### 1. Privacy Manifests ✅
**Commit**: `9b774b3` - Fix ITMS-91061: Add Apple Privacy Manifest support for Google SDKs

Updated Google SDKs to versions with privacy manifests:
- GoogleSignIn: 7.1.0+
- GTMAppAuth: 4.1.1+
- GTMSessionFetcher: 3.3.0+

**Result**: Build will be **VALID** in TestFlight ✅

### 2. os=apple Parameter Plugin ✅
**Commits**: `aad7acd`, `42632b8`, `c11e87a`, `9b4714c`

Added OSParameterPlugin with proper registration:
- Adds os=apple to ALL navigation
- Guarantees parameter on auth URLs
- Extensive logging for debugging

**Result**: Auth URLs will have `?os=apple` ✅

---

## 🚀 How to Build v1.5

### Step 1: Go to Codemagic

1. Open: **https://codemagic.io/apps**
2. Login with your account
3. Find: **MyCoachFinder** project

### Step 2: Start New Build

1. Click: **"Start new build"** button
2. Select workflow: **ios-production**
3. Select branch: **main**
4. Click: **"Start build"**

### Step 3: Wait for Build

Build will:
- ✅ Build v1.5 (build 13)
- ✅ Upload to App Store Connect
- ✅ **Automatically submit to TestFlight** (configured in codemagic.yaml:259)
- ⏱️ Wait 5-30 minutes for Apple review

### Step 4: Check TestFlight

After Apple review completes:

1. Go to: **App Store Connect → TestFlight**
2. Look for: **v1.5 (13)**
3. Status should be: **Ready to Test** ✅ (NOT "Invalid Binary")

---

## 📱 How to Test v1.5

### Install from TestFlight

1. Open TestFlight app on iPhone
2. Select: My Coach Finder
3. Install: **v1.5 (13)**

### Verify os=apple Plugin is Working

#### Method 1: Console Logs (Requires Mac)

Connect iPhone to Mac:
1. Open Xcode
2. Window → Devices and Simulators
3. Select your iPhone
4. Click "Open Console"
5. Filter for: `OSParameter`

**You should see**:
```
[OSParameter] ✅ Plugin loaded - will intercept ALL navigation to add os=apple
[OSParameter] 🎯 Critical URLs protected:
[OSParameter]    • /auth/login?os=apple
[OSParameter]    • /auth/register?os=apple
[OSParameter] ✅ Navigation interception active
```

#### Method 2: Test Page in App

In the app, navigate to: `force-os-parameter.html`

**Tests**:
1. Click "Test Plugin Available" → Should show ✅
2. Check current URL → Should show `?os=apple`
3. Click "Go to Login" → Should navigate to `/auth/login?os=apple`

#### Method 3: Backend Logs

Check your backend to see if it receives the parameter:
```
GET /auth/login?os=apple
GET /auth/register?os=apple
```

---

## 🎯 Expected Results

After installing v1.5 from TestFlight:

### TestFlight Status
- ✅ Build shows: **"Ready to Test"** (NOT "Invalid Binary")
- ✅ Version: 1.5 (13)
- ✅ Can install and run

### App Functionality
- ✅ App launches successfully
- ✅ All URLs have `?os=apple` parameter
- ✅ Auth URLs guaranteed: `/auth/login?os=apple`, `/auth/register?os=apple`
- ✅ Console shows `[OSParameter]` logs

### Backend Detection
- ✅ Backend receives `os=apple` parameter
- ✅ Can detect iOS app requests
- ✅ Can differentiate from web app

---

## 🔍 Troubleshooting

### If v1.5 Build is Still Invalid

**Check the error in App Store Connect**:
1. Go to: App Store Connect → TestFlight
2. Click on build 13
3. Read the error message
4. Send me the error details

**Common issues**:
- Missing export compliance info
- Missing icons
- API usage declaration needed

### If Plugin Still Doesn't Work

**After installing v1.5, if you STILL don't see `[OSParameter]` logs**:

1. Verify you're testing the RIGHT version:
   - In app: Check About/Settings for version number
   - Should show: v1.5 (13)

2. Check Xcode console output:
   - Connect iPhone to Mac
   - Open Xcode console
   - Send me the full console output

3. Test with force-os-parameter.html:
   - What does "Test Plugin Available" show?
   - Is plugin in the available plugins list?

---

## 📋 Quick Checklist

- [ ] Go to codemagic.io
- [ ] Start new build: ios-production workflow, main branch
- [ ] Wait for build to complete (20-30 min)
- [ ] Wait for Apple TestFlight review (5-30 min)
- [ ] Check TestFlight shows "Ready to Test" (not "Invalid Binary")
- [ ] Install v1.5 (13) from TestFlight
- [ ] Verify app launches
- [ ] Check console for `[OSParameter]` logs
- [ ] Test force-os-parameter.html
- [ ] Navigate to /auth/login
- [ ] Verify URL has `?os=apple`
- [ ] Check backend receives parameter

---

## 🎯 Summary

**Problem**: v1.4 builds 37/38 are Invalid Binary due to missing privacy manifests

**Solution**: Build v1.5 which includes:
1. ✅ Privacy manifests (so build is VALID)
2. ✅ os=apple plugin (so parameter works)

**Next step**: **Trigger Codemagic build NOW** at https://codemagic.io/apps

**Expected result**: Valid TestFlight build with working os=apple parameter

---

**After you trigger the build, it will take about 30-60 minutes total**:
- 20-30 min: Codemagic build
- 5-30 min: Apple TestFlight review
- Then: Ready to test! ✅
