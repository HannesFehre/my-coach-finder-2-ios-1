# iOS Testing on Linux - Complete Guide

## 🎯 Testing the os=apple Parameter on Linux

This guide shows you how to test your iOS app's `os=apple` parameter from Linux using RemoteDebug iOS WebKit Adapter.

---

## Prerequisites

✅ **Already Installed**:
- `libimobiledevice` (for iOS device communication)
- `remotedebug-ios-webkit-adapter` v0.4.2 (for debugging)

✅ **You Need**:
- Physical iPhone with TestFlight app
- USB cable to connect iPhone to Linux
- Chrome or Chromium browser on Linux

---

## Step 1: Prepare Your iPhone

### A. Install TestFlight Build

1. **Install TestFlight** from App Store (if not already installed)

2. **Accept TestFlight Invitation**:
   - Go to App Store Connect → TestFlight
   - Create a test group
   - Invite: `info@boothtml.com`
   - Accept invitation email on your iPhone
   - Install **Build 54** (or latest)

### B. Enable Web Inspector

**On your iPhone**:
```
Settings → Safari → Advanced → Web Inspector = ON
```

This is REQUIRED for remote debugging!

---

## Step 2: Connect iPhone to Linux

1. **Connect** iPhone via USB cable

2. **Unlock** your iPhone

3. **Trust** this computer when prompted:
   - Tap "Trust" on iPhone dialog
   - Enter your iPhone passcode

4. **Verify Connection**:
   ```bash
   cd /home/liz/Desktop/Module/MyCoachFinder/app/appel
   ./test-ios-debug.sh
   ```

---

## Step 3: Start Remote Debugging

### Option A: Use Helper Script (Recommended)

```bash
cd /home/liz/Desktop/Module/MyCoachFinder/app/appel
./test-ios-debug.sh
```

The script will:
- ✅ Detect your iPhone
- ✅ Show device info
- ✅ Start the debug adapter on port 9000
- ✅ Give you instructions

### Option B: Manual Start

```bash
remotedebug_ios_webkit_adapter --port=9000
```

**Expected output**:
```
remotedebug-ios-webkit-adapter is listening on port 9000
```

**Keep this terminal open!**

---

## Step 4: Open Chrome DevTools

1. **On your Linux machine**, open Chrome/Chromium

2. **Go to**: `chrome://inspect`

3. **Configure** (if needed):
   - Click "Configure"
   - Add: `localhost:9000`
   - Click "Done"

4. **Open MyCoachFinder app** on your iPhone

5. **You should see** in Chrome:
   ```
   Remote Target
   ├─ [Your iPhone Name]
   │  └─ MyCoachFinder (or app.my-coach-finder.com)
   │     [inspect] button
   ```

6. **Click "inspect"** → Chrome DevTools opens!

---

## Step 5: Test os=apple Parameter

### A. Check Console Logs

In Chrome DevTools Console, you should see:
```
[OSParameter] ✅ Plugin loaded - will intercept ALL navigation to add os=apple
[OSParameter] 🎯 Critical URLs protected:
[OSParameter]    • /auth/login?os=apple
[OSParameter]    • /auth/register?os=apple
```

### B. Navigate to Auth URLs

On your iPhone, navigate to:
1. **Login page** → `/auth/login`
2. **Register page** → `/auth/register`

### C. Verify os=apple Parameter

**In Chrome DevTools Console, run**:

```javascript
// Check current URL
console.log('Current URL:', window.location.href);

// Check if os=apple exists
console.log('Has os=apple?', window.location.search.includes('os=apple'));

// Monitor all navigation
let originalPushState = history.pushState;
history.pushState = function() {
    console.log('🔄 Navigation to:', arguments[2]);
    console.log('   Has os=apple?', arguments[2]?.includes('os=apple'));
    return originalPushState.apply(history, arguments);
};

window.addEventListener('popstate', () => {
    console.log('🔄 URL changed to:', window.location.href);
});

console.log('✅ Monitoring active! Navigate to /auth/login or /auth/register');
```

### D. Expected Results

When you navigate to `/auth/login`, you should see:

**In Console**:
```
[OSParameter] 🔍 shouldOverrideLoad CALLED!
[OSParameter] 🔍 Checking URL: https://app.my-coach-finder.com/auth/login
[OSParameter] ⚠️ URL MISSING os=apple: https://app.my-coach-finder.com/auth/login
[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple: /auth/login → /auth/login?os=apple
```

**In URL bar** (run `window.location.href`):
```
https://app.my-coach-finder.com/auth/login?os=apple
```

---

## Step 6: Debugging Tips

### View Network Requests
- Go to "Network" tab in DevTools
- Filter: `my-coach-finder.com`
- Check if requests have `?os=apple` parameter

### View WebView Structure
- Go to "Elements" tab
- Inspect DOM elements
- See actual rendered page

### Test Plugin Manually
```javascript
// Call plugin method from JavaScript
OSParameter.addOSParameter().then(result => {
    console.log('Plugin result:', result);
}).catch(err => {
    console.error('Plugin error:', err);
});
```

---

## Troubleshooting

### "No iOS device detected"
```bash
# Check USB connection
lsusb | grep -i apple

# List devices
idevice_id -l

# Pair device
idevicepair pair

# Trust computer on iPhone and try again
```

### "No remote targets in chrome://inspect"
1. Make sure iPhone is unlocked
2. Open the MyCoachFinder app on iPhone
3. Make sure Web Inspector is ON (Settings → Safari → Advanced)
4. Restart the adapter: `./test-ios-debug.sh`
5. Refresh chrome://inspect page

### "Cannot see console logs"
1. Make sure you clicked "inspect" on the correct app
2. Make sure app is running (not in background)
3. Try navigating to a page in the app
4. Check "Console" tab in DevTools

---

## Quick Test Checklist

- [ ] iPhone connected via USB
- [ ] iPhone unlocked and trusted
- [ ] Web Inspector enabled on iPhone
- [ ] TestFlight build 54 installed
- [ ] Adapter running (`./test-ios-debug.sh`)
- [ ] Chrome DevTools connected
- [ ] Navigate to `/auth/login`
- [ ] Console shows `[OSParameter]` logs
- [ ] URL has `?os=apple` parameter
- [ ] Navigate to `/auth/register`
- [ ] URL has `?os=apple` parameter

---

## Expected Final Result

✅ **Login URL**:
```
https://app.my-coach-finder.com/auth/login?os=apple
```

✅ **Register URL**:
```
https://app.my-coach-finder.com/auth/register?os=apple
```

✅ **Console Logs**:
```
[OSParameter] ✅ Plugin loaded
[OSParameter] 🎯 Critical URLs protected
[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple
```

---

## When You're Done

Press **Ctrl+C** in the terminal to stop the adapter.

You can restart anytime with:
```bash
./test-ios-debug.sh
```

---

**Good luck testing!** 🚀
