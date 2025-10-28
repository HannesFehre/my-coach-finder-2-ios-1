# VERIFICATION TESTS - CURL COMMANDS

Use these curl commands to verify your implementation is correct.

---

## 1. CHECK WEB APP IS ACCESSIBLE

```bash
curl -I https://app.my-coach-finder.com/go
```

**Expected Response:**
```
HTTP/2 200
content-type: text/html
```

✅ **Good:** Status 200 - Web app is accessible
❌ **Bad:** Status 404, 500, or timeout - Web app not reachable

---

## 2. CHECK IF BACKEND ENDPOINT EXISTS

```bash
curl -X POST https://app.my-coach-finder.com/auth/google/native \
  -H "Content-Type: application/json" \
  -v
```

**Expected Response Options:**

### Option A: Endpoint requires ID token (Good)
```
HTTP/2 401 Unauthorized
or
HTTP/2 400 Bad Request
{"error": "id_token required"}
```
✅ **This is GOOD** - Endpoint exists but needs valid token

### Option B: Endpoint not found (Bad)
```
HTTP/2 404 Not Found
```
❌ **This is BAD** - Backend endpoint doesn't exist

---

## 3. TEST BACKEND WITH DUMMY TOKEN

```bash
curl -X POST "https://app.my-coach-finder.com/auth/google/native?id_token=dummy_token_for_testing" \
  -H "Content-Type: application/json" \
  -v
```

**Expected Response:**
```
HTTP/2 401 Unauthorized
{"error": "Invalid token"}
or
{"error": "Token verification failed"}
```

✅ **Good:** Backend validates tokens (rejects dummy token)
❌ **Bad:** 404 Not Found - endpoint missing

---

## 4. CHECK GOOGLE OAUTH PAGE EXISTS

```bash
curl -I https://app.my-coach-finder.com/auth/google/login
```

**Expected:**
```
HTTP/2 302 Found
Location: https://accounts.google.com/...
```
or
```
HTTP/2 200
content-type: text/html
```

✅ **Good:** OAuth endpoint exists
❌ **Bad:** 404 - OAuth flow not configured

---

## 5. CHECK IF YOUR WEB APP HAS THE INTEGRATION

### This checks if your web app loads the Capacitor plugin

```bash
curl -s https://app.my-coach-finder.com/go | grep -i "GoogleAuth\|capacitor-google-auth"
```

**If you see output:**
✅ **Good:** Your web app has the plugin integration

**If no output:**
❌ **Bad:** Your web app doesn't import the plugin yet

---

## 6. CHECK TEST PAGE (LOCAL)

If you've deployed the iOS app:

```bash
# This only works on your local machine where iOS app files are
curl -s file:///home/liz/Desktop/Module/MyCoachFinder/app/appel/www/test-google-auth.html | grep "GoogleAuth"
```

**Expected:** Should see "GoogleAuth" in the HTML
✅ **Good:** Test page exists locally

---

## 7. CHECK CAPACITOR CONFIG

```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/capacitor.config.json | grep -A 5 "GoogleAuth"
```

**Expected:**
```json
"GoogleAuth": {
  "scopes": ["profile", "email"],
  "serverClientId": "353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com",
  "forceCodeForRefreshToken": true
}
```

✅ **Good:** Plugin is configured
❌ **Bad:** No GoogleAuth section

---

## 8. CHECK PACKAGE.JSON

```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/package.json | grep "capacitor-google-auth"
```

**Expected:**
```
"@codetrix-studio/capacitor-google-auth": "^3.4.0-rc.4"
```

✅ **Good:** Plugin is installed
❌ **Bad:** Not found

---

## 9. VERIFY PODFILE

```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/Podfile | grep -i "google"
```

**Expected:**
```
pod 'CodetrixStudioCapacitorGoogleAuth', :path => '../../node_modules/@codetrix-studio/capacitor-google-auth'
```

**Should NOT see:**
```
pod 'GoogleSignIn', '~> 7.0'  ← This should be REMOVED
```

✅ **Good:** Community plugin in Podfile, no manual GoogleSignIn
❌ **Bad:** Manual GoogleSignIn 7.0 still present (causes conflict)

---

## 10. CHECK INFO.PLIST

```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/App/Info.plist | grep -A 2 "GIDClientID"
```

**Expected:**
```xml
<key>GIDClientID</key>
<string>353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com</string>
```

✅ **Good:** Client ID configured
❌ **Bad:** Not found or wrong value

---

## COMPLETE VERIFICATION SCRIPT

Run all checks at once:

```bash
#!/bin/bash

echo "=== GOOGLE AUTH VERIFICATION ==="
echo ""

echo "1. Web App Accessible?"
curl -I https://app.my-coach-finder.com/go 2>&1 | head -1
echo ""

echo "2. Backend Endpoint Exists?"
curl -X POST https://app.my-coach-finder.com/auth/google/native -I 2>&1 | head -1
echo ""

echo "3. Backend Validates Tokens?"
curl -s -X POST "https://app.my-coach-finder.com/auth/google/native?id_token=test" 2>&1 | head -1
echo ""

echo "4. OAuth Page Exists?"
curl -I https://app.my-coach-finder.com/auth/google/login 2>&1 | head -1
echo ""

echo "5. Web App Has Plugin Integration?"
if curl -s https://app.my-coach-finder.com/go | grep -q "GoogleAuth\|capacitor-google-auth"; then
  echo "✅ Found GoogleAuth in web app"
else
  echo "❌ GoogleAuth NOT found in web app"
fi
echo ""

echo "6. iOS Package Has Plugin?"
if grep -q "capacitor-google-auth" /home/liz/Desktop/Module/MyCoachFinder/app/appel/package.json; then
  echo "✅ Plugin in package.json"
else
  echo "❌ Plugin NOT in package.json"
fi
echo ""

echo "7. Podfile Correct?"
if grep -q "CodetrixStudioCapacitorGoogleAuth" /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/Podfile; then
  echo "✅ Community plugin in Podfile"
else
  echo "❌ Community plugin NOT in Podfile"
fi
echo ""

if grep -q "GoogleSignIn.*7.0" /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/Podfile; then
  echo "⚠️  WARNING: Manual GoogleSignIn 7.0 found (should be removed)"
else
  echo "✅ No manual GoogleSignIn conflict"
fi
echo ""

echo "8. Capacitor Config Has Plugin?"
if grep -q "GoogleAuth" /home/liz/Desktop/Module/MyCoachFinder/app/appel/capacitor.config.json; then
  echo "✅ GoogleAuth configured in capacitor.config.json"
else
  echo "❌ GoogleAuth NOT configured"
fi
echo ""

echo "9. Info.plist Has Client ID?"
if grep -q "GIDClientID" /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/App/Info.plist; then
  echo "✅ GIDClientID in Info.plist"
else
  echo "❌ GIDClientID NOT in Info.plist"
fi

echo ""
echo "=== END VERIFICATION ==="
```

Save as `verify.sh` and run:

```bash
chmod +x verify.sh
./verify.sh
```

---

## INTERPRETATION GUIDE

### ✅ ALL GOOD if you see:
1. ✅ Web app returns 200
2. ✅ Backend returns 401/400 (validates tokens)
3. ✅ OAuth page exists
4. ✅ Plugin in package.json
5. ✅ Plugin in Podfile
6. ✅ No GoogleSignIn 7.0 conflict
7. ✅ Config has GoogleAuth
8. ✅ Info.plist has Client ID

### 🔴 MISSING WEB INTEGRATION if:
- ❌ Web app doesn't have GoogleAuth/capacitor-google-auth in source
- Backend and iOS are fine, but no JavaScript integration

### 🔴 BACKEND ISSUE if:
- ❌ Backend endpoint returns 404
- ❌ OAuth page doesn't exist

### 🔴 iOS CONFIG ISSUE if:
- ❌ Plugin not in package.json
- ❌ Plugin not in Podfile
- ❌ GoogleSignIn 7.0 conflict exists
- ❌ Info.plist missing Client ID

---

## QUICK TEST COMMANDS

### Test #1: Is iOS Backend Ready?
```bash
grep -q "capacitor-google-auth" /home/liz/Desktop/Module/MyCoachFinder/app/appel/package.json && echo "✅ iOS Ready" || echo "❌ iOS Not Ready"
```

### Test #2: Is Web App Updated?
```bash
curl -s https://app.my-coach-finder.com/go | grep -q "GoogleAuth" && echo "✅ Web App Updated" || echo "❌ Web App NOT Updated"
```

### Test #3: Is Backend Working?
```bash
curl -s -X POST "https://app.my-coach-finder.com/auth/google/native?id_token=test" -w "\nStatus: %{http_code}\n" | tail -1 | grep -q "401\|400" && echo "✅ Backend Works" || echo "❌ Backend Issue"
```

---

## EXPECTED RESULTS SUMMARY

| Component | Test | Expected Result |
|-----------|------|-----------------|
| Web App | curl -I .../go | HTTP 200 |
| Backend | curl .../auth/google/native | HTTP 401 (validates) |
| OAuth Page | curl .../auth/google/login | HTTP 200 or 302 |
| iOS Plugin | grep package.json | Found |
| Podfile | grep Podfile | CodetrixStudio found |
| Version Conflict | grep Podfile | No "GoogleSignIn 7.0" |
| Config | grep capacitor.config.json | GoogleAuth found |
| Info.plist | grep Info.plist | GIDClientID found |

---

## TROUBLESHOOTING

### If Backend Returns 404:
```bash
# Check what endpoints exist
curl -v https://app.my-coach-finder.com/auth/google/ 2>&1 | grep "< HTTP"
```

### If Web App Times Out:
```bash
# Check DNS resolution
nslookup app.my-coach-finder.com

# Check if server is up
ping -c 3 app.my-coach-finder.com
```

### If OAuth Page Missing:
```bash
# Check redirect
curl -L https://app.my-coach-finder.com/auth/google/login
```

---

Run these commands and share the output if you need help interpreting results!
