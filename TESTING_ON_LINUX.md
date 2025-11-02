# Testing iOS App on Linux

Since IPA files are native iOS apps, you **cannot run them directly on Linux or in a web browser**. However, here are all your testing options:

---

## ✅ Option 1: TestFlight (BEST - No macOS Needed!)

This is the recommended approach and works from anywhere.

### Step 1: Download Build from Codemagic

1. Go to [Codemagic Dashboard](https://codemagic.io/apps)
2. Select **my-coach-finder-2-ios-1**
3. Click on the latest successful build
4. Download the **App.ipa** artifact (optional - just to verify it exists)

### Step 2: Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Login with your Apple Developer account
3. Navigate to: **My Apps** → **My Coach Finder**
4. Click **TestFlight** tab

You should see your builds listed (v1.4 or v1.5).

### Step 3: Add Yourself as Internal Tester

1. Click **Internal Testing** (left sidebar)
2. Click the **+** icon next to "Testers"
3. Add your Apple ID email address
4. Save

You'll receive an email invitation.

### Step 4: Install on iPhone/iPad

1. **On your iOS device:**
   - Download **TestFlight** app from App Store (free)
   - Open the invitation email
   - Tap **View in TestFlight**
   - Tap **Install**

2. **App installs** - you can now test it!

### Step 5: Test the os=apple Parameter

#### Method A: Safari Web Inspector (Requires macOS)

1. Connect iPhone to Mac via USB
2. On iPhone: **Settings** → **Safari** → **Advanced** → Enable **Web Inspector**
3. On Mac: Open Safari → **Develop** → [Your iPhone] → **My Coach Finder**
4. Check **Console** tab for:
   ```
   [OSParameter] 🚀 JavaScript injection active
   [OSParameter] ✅ Added os=apple: /go → /go?os=apple
   ```
5. Check **Network** tab - all requests should have `?os=apple`

#### Method B: Backend Logging (Works from Linux!)

Add debug logging to your backend:

```python
@app.middleware("http")
async def log_ios_requests(request: Request, call_next):
    os_param = request.query_params.get("os")
    user_agent = request.headers.get("user-agent", "")

    if os_param == "apple" or "MyCoachFinder-iOS" in user_agent:
        print(f"📱 iOS APP REQUEST: {request.url}")
        print(f"   os parameter: {os_param}")
        print(f"   User-Agent: {user_agent[:100]}")

    response = await call_next(request)
    return response
```

Then watch backend logs:
```bash
sudo journalctl -u your-backend-service -f
```

#### Method C: In-App Test Page

Open in the app:
```
https://app.my-coach-finder.com/test-ios-detection.html
```

This page shows:
- ✅/❌ os=apple parameter detected
- ✅/❌ User-Agent contains "MyCoachFinder-iOS"
- Combined detection result

---

## 🔧 Option 2: Inspect IPA on Linux (Verify Compilation)

You can't **run** the IPA, but you can **inspect** it to verify the plugin was compiled.

### Download IPA from Codemagic

1. Go to [Codemagic Dashboard](https://codemagic.io/apps)
2. Select your app
3. Click on latest build
4. Download artifacts → **App.ipa**

### Inspect the IPA

```bash
cd /home/liz/Desktop/Module/MyCoachFinder/app/appel
./inspect-ipa.sh ~/Downloads/App.ipa
```

This will show:
- ✅ OSParameterPlugin compiled into binary
- ✅ Bundle version (should be 1.5)
- ✅ Google Sign-In configuration
- ✅ Capacitor plugins present

Example output:
```
==================================================
📦 IPA Inspector
==================================================

✅ Found app: App.app

==================================================
1️⃣ Checking for OSParameterPlugin
==================================================
✅ OSParameterPlugin found in binary

Plugin references:
OSParameter
OSParameterPlugin
[OSParameter] ✅ Plugin loaded
[OSParameter] ✅ JavaScript injected
...

==================================================
2️⃣ Bundle Information
==================================================
CFBundleShortVersionString => 1.5
CFBundleVersion => 13
CFBundleIdentifier => MyCoachFinder
CFBundleDisplayName => My Coach Finder
```

---

## 🌐 Option 3: Web Simulation (Limited Testing)

Test the **backend detection logic** (not the actual plugin):

### Start Local Server

```bash
cd /home/liz/Desktop/Module/MyCoachFinder/app/appel
python3 -m http.server 8080
```

### Open Test Page

**In browser:**
```
http://localhost:8080/test-ios-detection.html?os=apple
```

**To simulate iOS User-Agent**, use browser DevTools:
1. Open DevTools (F12)
2. Go to **Network conditions**
3. Set custom User-Agent:
   ```
   Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MyCoachFinder-iOS/1.5.13
   ```
4. Refresh page

The test page will show:
- ✅ os=apple parameter detected
- ✅ User-Agent contains "MyCoachFinder-iOS"
- ✅ Detected as iOS App

**Note:** This ONLY tests backend detection. It does NOT test:
- ❌ Actual JavaScript injection
- ❌ Navigation interception
- ❌ Native iOS features

---

## 🖥️ Option 4: Online iOS Simulators (Expensive/Limited)

### Appetize.io

Free tier: 100 minutes/month

1. Upload IPA to Appetize.io
2. Test in browser-based iOS simulator
3. Limited to simulator (no real device features)

**Limitations:**
- No push notifications
- No biometric auth
- Simulator environment (not real device)

### BrowserStack

Paid service with real iOS devices

1. Upload IPA to BrowserStack
2. Test on real iOS devices remotely
3. Full device features

**Cost:** ~$40/month

---

## 📊 Comparison of Options

| Method | Cost | macOS Required | Real Device | Backend Testing | Plugin Testing |
|--------|------|----------------|-------------|-----------------|----------------|
| **TestFlight** | Free | No | ✅ Yes | ✅ Yes | ✅ Yes |
| **IPA Inspection** | Free | No | ❌ No | ❌ No | ⚠️ Verify only |
| **Web Simulation** | Free | No | ❌ No | ✅ Yes | ❌ No |
| **Appetize.io** | Free tier | No | ❌ No | ✅ Yes | ⚠️ Partial |
| **BrowserStack** | $40/mo | No | ✅ Yes | ✅ Yes | ✅ Yes |

---

## ✅ Recommended Testing Flow

### For Development (Quick Checks):

1. **Build on Codemagic** → Wait for build success
2. **Inspect IPA** → Verify OSParameterPlugin compiled
3. **Backend logs** → Add debug logging for os=apple
4. **TestFlight** → Install and test on real device

### For Verification:

1. **TestFlight install** on iPhone/iPad
2. **Open app** and navigate around
3. **Check backend logs** from Linux:
   ```bash
   # SSH to backend server
   ssh your-server

   # Watch logs
   tail -f /var/log/your-app/access.log | grep "os=apple"
   ```
4. **Verify in logs:**
   ```
   📱 iOS APP REQUEST: https://app.my-coach-finder.com/go?os=apple
   📱 iOS APP REQUEST: https://app.my-coach-finder.com/dashboard?os=apple
   📱 iOS APP REQUEST: https://app.my-coach-finder.com/profile?os=apple
   ```

---

## 🐛 Troubleshooting

### "No builds in TestFlight"

**Cause:** Build hasn't finished uploading yet

**Solution:**
1. Check Codemagic build logs - look for "Upload succeeded"
2. Wait 5-10 minutes for App Store Connect processing
3. Refresh TestFlight tab

### "Can't add testers"

**Cause:** Apple Developer account not set up for TestFlight

**Solution:**
1. Go to **Users and Access** in App Store Connect
2. Add your email as **Admin** or **App Manager**
3. Accept invitation email

### "os=apple parameter not showing"

**Cause:** JavaScript injection might not be working

**Solution:**
1. Download IPA and inspect it
2. Verify OSParameterPlugin is compiled
3. Check Xcode console logs (if have access to Mac)
4. Add backend logging to see what parameters arrive

---

## 📝 Quick Command Reference

```bash
# Download IPA from Codemagic
# (Use web UI, or if you have API token:)
curl -H "x-auth-token: YOUR_TOKEN" \
  https://api.codemagic.io/builds/BUILD_ID/artifacts/App.ipa \
  -o App.ipa

# Inspect IPA
./inspect-ipa.sh App.ipa

# Serve test page
python3 -m http.server 8080

# Watch backend logs (if SSH access)
ssh your-server
tail -f /var/log/app/access.log | grep --color "os=apple"
```

---

## 🎯 Success Criteria

Your v1.5 build is successful if:

✅ **IPA inspection shows:**
- OSParameterPlugin found in binary
- Bundle version is 1.5
- GoogleSignIn configured

✅ **Backend logs show:**
- `GET /go?os=apple` on app startup
- `GET /dashboard?os=apple` on navigation
- User-Agent contains `MyCoachFinder-iOS/1.5`

✅ **Test page shows:**
- ✅ os parameter detected
- ✅ User-Agent detected
- ✅ Detected as iOS App

---

## 🚀 Next Steps

1. **Trigger Codemagic build** for version 1.5 (privacy manifests + os=apple fix)
2. **Wait for upload** to App Store Connect
3. **Install via TestFlight** on iPhone/iPad
4. **Add backend logging** to verify os=apple parameter
5. **Test navigation** - check all pages have os=apple

---

**Remember:** You CANNOT run iOS apps on Linux. TestFlight is your best friend! 🎉
