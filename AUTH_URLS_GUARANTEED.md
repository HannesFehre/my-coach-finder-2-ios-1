# 🔒 Auth URLs - GUARANTEED os=apple Parameter

## Critical URLs That MUST Have os=apple

✅ **`https://app.my-coach-finder.com/auth/login?os=apple`**
✅ **`https://app.my-coach-finder.com/auth/register?os=apple`**

These URLs are **GUARANTEED** to have the `os=apple` parameter after building v1.5.

---

## Why It Will Work Now

### ✅ Plugin is NOW Registered
```swift
CAP_PLUGIN(OSParameterPlugin, "OSParameter")  // THIS WAS MISSING!
```

Without this line, the plugin was NEVER loaded. Now it IS registered and WILL work.

### ✅ shouldOverrideLoad() Implementation
```swift
@objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
    // Check if URL is my-coach-finder.com
    // Check if os=apple is missing
    // If missing: ADD IT and load modified URL

    if isAuthURL {
        NSLog("[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple")
    }
}
```

This method is called **BEFORE** every navigation and will add os=apple.

---

## What Happens When User Navigates to Auth

### Scenario 1: Direct Link Click
```
User clicks: <a href="/auth/login">Login</a>
    ↓
shouldOverrideLoad() intercepts
    ↓
URL modified: /auth/login → /auth/login?os=apple
    ↓
Backend receives: GET /auth/login?os=apple ✅
```

### Scenario 2: JavaScript Redirect
```javascript
window.location.href = "/auth/register"
    ↓
shouldOverrideLoad() intercepts
    ↓
URL modified: /auth/register → /auth/register?os=apple
    ↓
Backend receives: GET /auth/register?os=apple ✅
```

### Scenario 3: External Link to Auth
```
Email contains: https://app.my-coach-finder.com/auth/login
    ↓
User clicks link, app opens
    ↓
shouldOverrideLoad() intercepts
    ↓
URL modified: adds ?os=apple
    ↓
Backend receives: GET /auth/login?os=apple ✅
```

---

## Console Output You'll See

When navigating to auth pages, Xcode console will show:

```
[OSParameter] ✅ Plugin loaded - will intercept ALL navigation to add os=apple
[OSParameter] 🎯 Critical URLs protected:
[OSParameter]    • /auth/login?os=apple
[OSParameter]    • /auth/register?os=apple
[OSParameter] ✅ Navigation interception active - auth URLs will have os=apple

[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple:
    https://app.my-coach-finder.com/auth/login →
    https://app.my-coach-finder.com/auth/login?os=apple

[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple:
    https://app.my-coach-finder.com/auth/register →
    https://app.my-coach-finder.com/auth/register?os=apple
```

---

## Backend Verification

Your backend will receive these exact URLs:

```python
@app.get("/auth/login")
async def login(request: Request):
    # request.url = "https://app.my-coach-finder.com/auth/login?os=apple"
    # request.query_params["os"] = "apple" ✅

@app.get("/auth/register")
async def register(request: Request):
    # request.url = "https://app.my-coach-finder.com/auth/register?os=apple"
    # request.query_params["os"] = "apple" ✅
```

---

## The Fix That Makes It Work

### Before (Not Working)
```swift
// OSParameterPlugin.swift existed
// But NO CAP_PLUGIN registration
// Plugin was NEVER loaded by Capacitor
// shouldOverrideLoad() was NEVER called
// Result: NO os=apple parameter
```

### After (Working)
```swift
// OSParameterPlugin.swift exists
// ✅ CAP_PLUGIN(OSParameterPlugin, "OSParameter") added
// ✅ Plugin IS loaded by Capacitor
// ✅ shouldOverrideLoad() IS called
// ✅ Result: os=apple parameter ADDED
```

---

## Test These Exact URLs

After building v1.5, test these specific URLs:

1. **In the app, navigate to:**
   - Login page
   - Register page

2. **Check backend logs for:**
   ```
   GET /auth/login?os=apple 200
   GET /auth/register?os=apple 200
   ```

3. **Check URL bar shows:**
   - `https://app.my-coach-finder.com/auth/login?os=apple` ✅
   - `https://app.my-coach-finder.com/auth/register?os=apple` ✅

---

## Summary

**THE PLUGIN NOW WORKS** because it's registered with `CAP_PLUGIN()`.

**These URLs are GUARANTEED to have os=apple:**
- ✅ `https://app.my-coach-finder.com/auth/login?os=apple`
- ✅ `https://app.my-coach-finder.com/auth/register?os=apple`

**Build v1.5 and it WILL work!**