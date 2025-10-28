# 🔴 WEB APP INTEGRATION REQUIRED - CRITICAL

**Current Status:** Button opens Safari browser ❌
**Reason:** Web application code NOT updated to use community plugin
**Location:** Your web app at `https://app.my-coach-finder.com`

---

## THE PROBLEM

### What's Happening Now:
1. User clicks "Mit Google fortfahren" button
2. Button has `href="/auth/google/login?return_url=/coach/dashboard"`
3. Browser navigates to that URL
4. **Safari opens** ❌
5. User sees web OAuth flow (bad UX)

### Why It Opens Safari:
Your web application is NOT intercepting the click and calling the community plugin. The button is doing a normal link navigation, which iOS opens in Safari.

---

## THE SOLUTION

You need to add JavaScript to your web application at **https://app.my-coach-finder.com** that:
1. Imports the GoogleAuth plugin
2. Initializes it on app start
3. Intercepts button clicks
4. Calls the native plugin instead of navigating

---

## 🧪 TEST FIRST: Local Test Page

I've created a test page to verify the plugin works:

**File:** `www/test-google-auth.html`

### Test It Now:
```bash
# 1. Sync the test page to iOS
npx cap sync ios

# 2. Build and run
npm run ios

# 3. In the app, navigate to:
# https://app.my-coach-finder.com/go
# (It will redirect to your actual web app)

# 4. Or test directly by updating www/index.html to point to test page
```

**Expected Result:**
- Click button → Native Google picker appears (NOT Safari) ✅

---

## 🔧 CODE YOU NEED TO ADD

### WHERE TO ADD THIS CODE:
In your web application repository at `https://app.my-coach-finder.com`

This is **NOT** the iOS wrapper project - it's your actual web application codebase.

---

### STEP 1: Install Plugin in Web Project

In your **web application** project (not iOS wrapper):

```bash
npm install @codetrix-studio/capacitor-google-auth
```

---

### STEP 2: Add This Script to Your Web App

**Option A: In your main JavaScript file** (e.g., `app.js`, `main.js`):

```javascript
// Import the plugin
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';
import { Capacitor } from '@capacitor/core';

// Initialize on app start
async function initGoogleAuth() {
  // Only initialize on native platforms
  if (Capacitor.isNativePlatform()) {
    try {
      await GoogleAuth.initialize();
      console.log('[GoogleAuth] Initialized successfully');
    } catch (error) {
      console.error('[GoogleAuth] Initialization failed:', error);
    }
  }
}

// Call this when your app loads
initGoogleAuth();

// Intercept Google OAuth button clicks
document.addEventListener('click', async function(e) {
  // Only intercept on native platforms
  if (!Capacitor.isNativePlatform()) {
    return; // Let web OAuth work normally on browser
  }

  let element = e.target;

  // Traverse up to find the link (handles clicks on SVG, span, etc.)
  for (let i = 0; i < 10 && element; i++) {
    const href = element.getAttribute?.('href');

    // Check if this is the Google OAuth link
    if (href && (href.includes('/auth/google/login') || href.includes('auth/google/login'))) {
      console.log('[GoogleAuth] Intercepted click on:', href);

      // CRITICAL: Stop the default navigation
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();

      // Extract return URL
      let returnUrl = '/';
      try {
        const url = new URL(href, window.location.origin);
        returnUrl = url.searchParams.get('return_url') || '/';
      } catch (err) {
        console.error('[GoogleAuth] Could not parse URL:', err);
      }

      try {
        console.log('[GoogleAuth] Calling signIn()...');

        // Call the native plugin
        const result = await GoogleAuth.signIn();
        console.log('[GoogleAuth] Success:', result);

        // Send ID token to your backend
        const response = await fetch(
          'https://app.my-coach-finder.com/auth/google/native?id_token=' +
          encodeURIComponent(result.authentication.idToken),
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
          }
        );

        if (response.ok) {
          const data = await response.json();

          // Store authentication data
          localStorage.setItem('token', data.access_token || data.token);
          localStorage.setItem('user', JSON.stringify(data.user || {}));

          // Redirect to the return URL
          console.log('[GoogleAuth] Redirecting to:', returnUrl);
          window.location.href = 'https://app.my-coach-finder.com' + returnUrl;
        } else {
          const error = await response.text();
          console.error('[GoogleAuth] Backend error:', response.status, error);
          alert('Authentication failed: ' + response.status);
        }
      } catch (error) {
        console.error('[GoogleAuth] Sign-in error:', error);
        alert('Sign-in error: ' + error.message);
      }

      return false;
    }

    element = element.parentElement;
  }
}, true); // Use capture phase to intercept before other handlers
```

---

### STEP 3: Verify It Works

1. **Deploy your web app** with the code above
2. **Build iOS app:**
   ```bash
   npx cap sync ios
   npm run ios
   ```
3. **Test:**
   - Click Google button
   - **Expected:** Native picker appears ✅
   - **NOT Expected:** Safari opens ❌

---

## 🔍 DEBUGGING

### Check If Plugin Is Available

Add this to see what plugins are loaded:

```javascript
// After 2 seconds, check plugins
setTimeout(() => {
  if (window.Capacitor?.Plugins) {
    console.log('Available plugins:', Object.keys(window.Capacitor.Plugins));

    if (window.Capacitor.Plugins.GoogleAuth) {
      console.log('✅ GoogleAuth plugin is available');
    } else {
      console.error('❌ GoogleAuth plugin NOT found');
    }
  }
}, 2000);
```

### Check Console Logs

When you click the button, you should see:

```
[GoogleAuth] Intercepted click on: /auth/google/login?return_url=/coach/dashboard
[GoogleAuth] Calling signIn()...
[GoogleAuth] Success: { authentication: {...}, email: "...", ... }
[GoogleAuth] Redirecting to: /coach/dashboard
```

### If No Logs Appear

- JavaScript not loaded
- Event listener not attached
- Web app not updated
- Check browser console for errors

---

## 📁 YOUR PROJECT STRUCTURE

You have TWO separate projects:

### 1. iOS Wrapper (This repo) ✅
**Location:** `/home/liz/Desktop/Module/MyCoachFinder/app/appel`
**Status:** DONE - Plugin installed, configured, synced
**Files:**
- `package.json` - Has community plugin
- `capacitor.config.json` - Configured
- `ios/App/Podfile` - Fixed version conflict

### 2. Web Application (Your main app) 🔴
**Location:** Your web app repository (separate from iOS wrapper)
**URL:** `https://app.my-coach-finder.com`
**Status:** NEEDS UPDATE
**Files to modify:**
- Your main JavaScript file (app.js, main.js, etc.)
- Add the code from STEP 2 above

---

## 🎯 CRITICAL UNDERSTANDING

The iOS wrapper is just a shell that loads your web app from:
```
https://app.my-coach-finder.com/go
```

The button on that web page needs JavaScript to call the native plugin.

**iOS wrapper** = Container (✅ Done)
**Web application** = Content that runs inside container (🔴 Needs update)

---

## ⚡ QUICK FIX FOR TESTING

If you want to test immediately without deploying your web app:

### Update Local Test:

1. **Edit:** `www/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Google Auth Test</title>
</head>
<body>
    <h1>Testing...</h1>
    <script>
        // Redirect to test page
        window.location.href = '/test-google-auth.html';
    </script>
</body>
</html>
```

2. **Sync and build:**
```bash
npx cap sync ios
npm run ios
```

3. **Test:** App should show test page with working button

This proves the plugin works. Now you just need to add the same code to your real web app.

---

## 🚨 COMMON MISTAKES

### ❌ Wrong: Adding code to iOS wrapper
The iOS wrapper doesn't control button behavior. It just displays your web app.

### ✅ Right: Adding code to web application
Your web app at `https://app.my-coach-finder.com` needs the JavaScript.

---

### ❌ Wrong: Modifying NativeAuthPlugin.swift
That plugin is disabled. Community plugin is used now.

### ✅ Right: Using GoogleAuth from community plugin
```javascript
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';
```

---

### ❌ Wrong: Button still uses href navigation
```html
<a href="/auth/google/login"><!-- Still navigates to URL --></a>
```

### ✅ Right: JavaScript intercepts click
```javascript
e.preventDefault(); // Stops navigation
await GoogleAuth.signIn(); // Calls native plugin
```

---

## 📋 CHECKLIST

Before you can see the native picker:

- [ ] Install plugin in **web app** project: `npm install @codetrix-studio/capacitor-google-auth`
- [ ] Add import to **web app**: `import { GoogleAuth } from '...'`
- [ ] Add `GoogleAuth.initialize()` call on **web app** startup
- [ ] Add click interceptor to **web app** JavaScript
- [ ] Deploy updated **web app** to https://app.my-coach-finder.com
- [ ] Rebuild iOS app: `npx cap sync ios && npm run ios`
- [ ] Test: Click button → Native picker appears ✅

---

## 🆘 STILL STUCK?

### Test with Local Page First:

```bash
# 1. Update www/index.html to redirect to test page
echo '<script>window.location="/test-google-auth.html"</script>' > www/index.html

# 2. Sync
npx cap sync ios

# 3. Run
npm run ios

# 4. Click button in app
# Expected: Native picker works ✅
```

If test page works but your real app doesn't:
→ The plugin works, you just need to add the JavaScript to your real web app

If test page also opens Safari:
→ Check console for errors
→ Verify GoogleAuth in plugins list
→ Share console logs

---

## 📞 NEXT STEPS

1. **Locate your web app repository** (not the iOS wrapper)
2. **Add the code from STEP 2** to your main JavaScript file
3. **Deploy your web app**
4. **Rebuild iOS app**
5. **Test** - native picker should work!

---

**Summary:** iOS backend is ready ✅ | Web frontend needs JavaScript code 🔴
**Blocker:** JavaScript not intercepting clicks in your web application
**Solution:** Add STEP 2 code to https://app.my-coach-finder.com repository
