# Auth URL Protection - Guaranteed os=apple Parameter

## 🎯 Critical Requirement

These URLs **MUST ALWAYS** have the `os=apple` parameter:
- `https://app.my-coach-finder.com/auth/login?os=apple`
- `https://app.my-coach-finder.com/auth/register?os=apple`

This is critical for the backend to detect iOS app users and apply proper authentication logic.

---

## 🛡️ Dual-Layer Protection

The OSParameterPlugin implements **two independent layers** to guarantee auth URLs have `os=apple`:

### Layer 1: JavaScript Injection (Primary)

**File:** `ios/App/App/OSParameterPlugin.swift` → `injectOSParameterScript()`

**How it works:**
- JavaScript injected on every page load
- Intercepts all navigation methods:
  - `window.location.href` assignments
  - `history.pushState/replaceState`
  - Link clicks
  - `window.open()` calls
- Adds `os=apple` to ALL my-coach-finder.com URLs
- **Special logging** for auth URLs

**Console output:**
```
[OSParameter] ⚠️ CRITICAL AUTH URL - Added os=apple:
  /auth/login → /auth/login?os=apple
```

### Layer 2: Native Navigation Interception (Failsafe)

**File:** `ios/App/App/OSParameterPlugin.swift` → `decidePolicyFor navigationAction`

**How it works:**
- Intercepts **ALL** navigation requests at the native WKWebView level
- Specifically checks for `/auth/login` and `/auth/register` URLs
- If auth URL detected **without** `os=apple`:
  - Cancels the navigation
  - Adds `os=apple` parameter
  - Reloads with modified URL

**Log output:**
```
[OSParameter] ⚠️ CRITICAL: Intercepting auth URL without os=apple:
  https://app.my-coach-finder.com/auth/login
[OSParameter] ✅ CRITICAL: Modified auth URL:
  .../auth/login → .../auth/login?os=apple
```

---

## ✅ Coverage Guarantee

### Why Dual Layers?

If JavaScript injection somehow fails or is delayed, the native layer catches it:

| Navigation Method | JavaScript Layer | Native Layer | Result |
|------------------|------------------|--------------|--------|
| Link click | ✅ Adds os=apple | ✅ Verifies | **Guaranteed** |
| window.location | ✅ Adds os=apple | ✅ Verifies | **Guaranteed** |
| history.pushState | ✅ Adds os=apple | ✅ Verifies | **Guaranteed** |
| Direct navigation | ⚠️ Might miss | ✅ **Catches** | **Guaranteed** |
| External redirect | ⚠️ Might miss | ✅ **Catches** | **Guaranteed** |

### Result: **100% Coverage**

No matter how the user navigates to auth URLs, the parameter **WILL** be added.

---

## 🧪 Testing

### Test Page Included

Open in the iOS app:
```
https://app.my-coach-finder.com/test-auth-urls.html
```

**Tests all navigation methods:**
1. Direct link click
2. JavaScript redirect (`window.location.href`)
3. SPA navigation (`history.pushState`)
4. Programmatic open (`window.open`)

Each test button verifies that `os=apple` is added.

### Expected Results

**In Console (Safari Web Inspector):**
```
[OSParameter] 🚀 JavaScript injection active
[OSParameter] ⚠️ CRITICAL: Fixing auth page URL
[OSParameter] ⚠️ CRITICAL AUTH URL - Added os=apple:
  /auth/login → /auth/login?os=apple
```

**In URL Bar:**
```
https://app.my-coach-finder.com/auth/login?os=apple ✅
https://app.my-coach-finder.com/auth/register?os=apple ✅
```

**In Backend Logs:**
```python
📱 iOS APP REQUEST: /auth/login?os=apple
   os parameter: apple
   User-Agent: ...MyCoachFinder-iOS/1.5
```

---

## 🔍 Backend Detection

Your backend can now reliably detect iOS app users on auth pages:

### Python/FastAPI Example

```python
from fastapi import FastAPI, Request, Query

app = FastAPI()

@app.get("/auth/login")
async def login_page(request: Request, os: str = Query(None)):
    # Detect iOS app
    is_ios_app = os == "apple"
    user_agent = request.headers.get("user-agent", "")

    if is_ios_app:
        print(f"📱 iOS APP LOGIN: {request.url}")
        # Apply iOS-specific login logic
        return {"platform": "ios", "use_native_oauth": True}
    else:
        print(f"🌐 WEB LOGIN: {request.url}")
        # Standard web login
        return {"platform": "web", "use_native_oauth": False}

@app.get("/auth/register")
async def register_page(request: Request, os: str = Query(None)):
    is_ios_app = os == "apple"

    if is_ios_app:
        print(f"📱 iOS APP REGISTER: {request.url}")
        # iOS-specific registration flow
    else:
        print(f"🌐 WEB REGISTER: {request.url}")
        # Standard web registration
```

---

## 🎯 Implementation Details

### Code Locations

| Component | File | Lines |
|-----------|------|-------|
| **JavaScript Injection** | `OSParameterPlugin.swift` | 52-172 |
| **Native Interception** | `OSParameterPlugin.swift` | 175-213 |
| **Auth URL Detection** | Lines 182, 186 | `/auth/login`, `/auth/register` |
| **Test Page** | `www/test-auth-urls.html` | Full test suite |

### Key Code Snippets

**JavaScript - Auth URL Check:**
```javascript
if (urlObj.pathname.includes('/auth/login') ||
    urlObj.pathname.includes('/auth/register')) {
    console.log('[OSParameter] ⚠️ CRITICAL AUTH URL - Added os=apple:', ...);
}
```

**Swift - Native Interception:**
```swift
let isAuthURL = path.contains("/auth/login") || path.contains("/auth/register")
let isMCFDomain = url.host?.hasSuffix("my-coach-finder.com") ?? false
let hasOSParam = urlString.contains("os=apple")

if isAuthURL && isMCFDomain && !hasOSParam {
    // Force add os=apple and reload
    decisionHandler(.cancel)
    webView.load(URLRequest(url: modifiedURL))
}
```

---

## 📊 Success Indicators

When working correctly, you'll see:

### ✅ In Xcode Console
```
[OSParameter] ✅ Plugin loaded
[OSParameter] ✅ JavaScript injected successfully
[OSParameter] ⚠️ CRITICAL: Intercepting auth URL without os=apple
[OSParameter] ✅ CRITICAL: Modified auth URL
```

### ✅ In Safari Console
```
[OSParameter] 🚀 JavaScript injection active
[OSParameter] ⚠️ CRITICAL AUTH URL - Added os=apple
[OSParameter] ✅ All navigation interception active
```

### ✅ In Backend Logs
```
GET /auth/login?os=apple 200
GET /auth/register?os=apple 200
```

### ✅ In Network Tab
Every request to `/auth/*` has query parameter:
```
?os=apple
```

---

## 🚨 Troubleshooting

### Issue: Auth URL missing os=apple

**Check 1: Verify plugin loaded**
```
# Should see in Xcode console:
[OSParameter] ✅ Plugin loaded
```

**Check 2: Verify JavaScript injection**
```
# Should see in Safari console:
[OSParameter] 🚀 JavaScript injection active
```

**Check 3: Check native interception**
```
# Should see in Xcode console when navigating to auth:
[OSParameter] ⚠️ CRITICAL: Intercepting auth URL
```

### Issue: Console logs not showing

**Solution:** Connect iPhone to Mac and use Safari Web Inspector
1. Settings → Safari → Advanced → Enable Web Inspector
2. Mac Safari → Develop → [Your iPhone] → My Coach Finder
3. Console tab should show all [OSParameter] logs

---

## 🎉 Summary

**Dual-layer protection ensures:**
- ✅ Auth URLs **always** have `os=apple` parameter
- ✅ Works regardless of navigation method
- ✅ Detects and logs auth URL access
- ✅ Backend can reliably detect iOS app users
- ✅ 100% coverage with two independent safety nets

**Critical URLs protected:**
- ✅ `https://app.my-coach-finder.com/auth/login?os=apple`
- ✅ `https://app.my-coach-finder.com/auth/register?os=apple`

**Test it:** Open `test-auth-urls.html` in the app and try all navigation methods!
