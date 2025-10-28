# GOOGLE AUTH MIGRATION GUIDE
## From Custom NativeAuthPlugin → Community Plugin

**Migration Date:** 2025-10-28
**Status:** ✅ Backend Setup Complete - Frontend Integration Needed

---

## WHAT WAS DONE

### ✅ 1. Package Installation
```bash
npm install @codetrix-studio/capacitor-google-auth
```

**Installed:** `@codetrix-studio/capacitor-google-auth@3.4.0-rc.4`

### ✅ 2. Capacitor Configuration
**File:** `capacitor.config.json`

```json
{
  "plugins": {
    "GoogleAuth": {
      "scopes": ["profile", "email"],
      "serverClientId": "353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com",
      "forceCodeForRefreshToken": true
    }
  }
}
```

### ✅ 3. Custom Plugin Disabled
**File:** `ios/App/App/NativeAuthPlugin.swift` → `NativeAuthPlugin.swift.backup`

The custom plugin is now disabled but preserved for reference.

### ✅ 4. iOS Project Synced
```bash
npx cap sync ios
```

**Detected Plugins:**
- @capacitor/browser@6.0.5
- @capacitor/preferences@6.0.3
- @capacitor/push-notifications@6.0.4
- ✅ @codetrix-studio/capacitor-google-auth@3.4.0-rc.4

---

## WHAT NEEDS TO BE DONE (Web/Frontend)

### 🔴 CRITICAL: Update Web Application Code

Your web application at `https://app.my-coach-finder.com` needs to be updated to use the community plugin API instead of the old custom plugin.

### Option A: Intercept Button Clicks (Recommended)

**Current Button HTML:**
```html
<a href="/auth/google/login?return_url=/coach/dashboard" class="oauth-btn">
  <svg><!-- Google logo --></svg>
  <span>Mit Google fortfahren</span>
</a>
```

**Add This JavaScript to Your Web App:**
```javascript
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';

// Initialize plugin on app load
async function initGoogleAuth() {
  if (window.Capacitor?.isNativePlatform?.()) {
    await GoogleAuth.initialize();
  }
}

// Call on app start
initGoogleAuth();

// Intercept Google OAuth button clicks
document.addEventListener('click', async function(e) {
  // Find if click is on Google OAuth button
  let element = e.target;
  for (let i = 0; i < 10 && element; i++) {
    const href = element.getAttribute?.('href');

    if (href && href.includes('/auth/google/login')) {
      console.log('[GoogleAuth] Intercepted click on:', href);

      // Only use native auth on iOS/Android
      if (window.Capacitor?.isNativePlatform?.()) {
        e.preventDefault();
        e.stopPropagation();

        // Extract return_url
        const returnUrl = new URL(href, window.location.origin)
          .searchParams.get('return_url') || '/';

        try {
          // Use community plugin
          const result = await GoogleAuth.signIn();
          console.log('[GoogleAuth] Sign-in result:', result);

          // Send to your backend
          const response = await fetch(
            'https://app.my-coach-finder.com/auth/google/native?id_token=' +
            encodeURIComponent(result.authentication.idToken),
            {
              method: 'POST',
              headers: {'Content-Type': 'application/json'}
            }
          );

          if (response.ok) {
            const data = await response.json();
            localStorage.setItem('token', data.access_token || data.token);
            localStorage.setItem('user', JSON.stringify(data.user || {}));
            window.location.href = 'https://app.my-coach-finder.com' + returnUrl;
          } else {
            alert('Authentication failed: ' + response.status);
          }
        } catch (err) {
          console.error('[GoogleAuth] Error:', err);
          alert('Sign-in error: ' + err.message);
        }

        return false;
      }
    }
    element = element.parentElement;
  }
}, true); // Capture phase
```

### Option B: Direct Integration (Alternative)

If you want to replace the button entirely:

```javascript
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';

async function handleGoogleLogin(returnUrl) {
  try {
    // Initialize if needed
    await GoogleAuth.initialize();

    // Trigger sign-in
    const result = await GoogleAuth.signIn();

    // result contains:
    // - authentication.idToken
    // - authentication.accessToken
    // - email
    // - familyName
    // - givenName
    // - id
    // - name
    // - imageUrl

    // Send ID token to backend
    const response = await fetch(
      `https://app.my-coach-finder.com/auth/google/native?id_token=${result.authentication.idToken}`,
      {
        method: 'POST',
        headers: {'Content-Type': 'application/json'}
      }
    );

    if (response.ok) {
      const data = await response.json();
      localStorage.setItem('token', data.access_token);
      localStorage.setItem('user', JSON.stringify(data.user));
      window.location.href = 'https://app.my-coach-finder.com' + returnUrl;
    }
  } catch (error) {
    console.error('Google Sign-In failed:', error);
    // Fallback to web flow
    window.location.href = '/auth/google/login?return_url=' + returnUrl;
  }
}
```

---

## API DIFFERENCES

### OLD Custom Plugin API:
```javascript
window.Capacitor.Plugins.NativeAuth.signInWithGoogle()
// Returns: { idToken, email, displayName, photoUrl }
```

### NEW Community Plugin API:
```javascript
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';

await GoogleAuth.initialize();
const result = await GoogleAuth.signIn();
// Returns: {
//   authentication: { idToken, accessToken },
//   email, name, givenName, familyName,
//   id, imageUrl
// }
```

**Key Differences:**
1. **Must import** from package (not window.Capacitor.Plugins)
2. **Must call initialize()** once on app load
3. **Different response structure** (nested authentication object)
4. **More user data** available (familyName, givenName, etc.)

---

## TESTING CHECKLIST

### Before Building:

- [ ] Web app updated to use new `GoogleAuth` API
- [ ] Import statement added to web code
- [ ] `GoogleAuth.initialize()` called on app start
- [ ] Button click interceptor updated (if using Option A)
- [ ] Backend endpoint still accepts ID tokens at `/auth/google/native`

### After Building:

- [ ] Build app: `npm run ios` or Xcode
- [ ] Wait for diagnostic alerts (2 seconds after launch)
- [ ] Alert 1 should show: `GoogleAuth` in available plugins list
- [ ] Alert 2 should show: Plugin registered
- [ ] Click Google OAuth button
- [ ] **Native Google account picker appears** (NOT Safari)
- [ ] Select Google account
- [ ] Check console for sign-in result
- [ ] Verify redirect to return_url works
- [ ] Confirm token saved in localStorage

### Safari Web Inspector Console:

Connect device and check for:
```
[GoogleAuth] Intercepted click on: /auth/google/login?return_url=/coach/dashboard
[GoogleAuth] Sign-in result: { authentication: {...}, email: "...", ... }
```

---

## TROUBLESHOOTING

### Issue: Alert shows "GoogleAuth: NO"
**Cause:** Plugin not registered (shouldn't happen with community plugin)
**Fix:** Run `npx cap sync ios` again

### Issue: Import error in web code
**Cause:** Package not installed in web project
**Fix:** Make sure your web app's package.json includes the plugin

### Issue: Native picker doesn't appear
**Cause:** Web code still using old API or not intercepting clicks
**Fix:** Verify web code is updated with new API

### Issue: "GoogleAuth is not defined"
**Cause:** Import statement missing
**Fix:** Add `import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';`

### Issue: Backend returns 401
**Cause:** ID token format might be different
**Fix:** Check backend logs, verify token is in `result.authentication.idToken`

---

## ROLLBACK PLAN (If Needed)

If community plugin doesn't work:

```bash
# 1. Remove community plugin
npm uninstall @codetrix-studio/capacitor-google-auth

# 2. Restore custom plugin
mv ios/App/App/NativeAuthPlugin.swift.backup ios/App/App/NativeAuthPlugin.swift

# 3. Remove plugin config from capacitor.config.json
# Delete the "plugins" section

# 4. Re-sync
npx cap sync ios
```

---

## WHY THIS FIXES THE PROBLEM

According to the Technical Analysis Report:

### Problem with Custom Plugin:
- ❌ Capacitor 6.0 broke auto-registration for local plugins
- ❌ Works in local dev (cached state) but fails in CI/CD
- ❌ `window.Capacitor.Plugins.NativeAuth` returns `undefined` in production
- ❌ Button falls back to opening Safari

### Why Community Plugin Works:
- ✅ NPM plugins auto-register in Capacitor 6.0
- ✅ No registration code needed
- ✅ Works identically in local dev and CI/CD builds
- ✅ Battle-tested by community (95% success rate)
- ✅ Maintained and updated for SDK changes

### Expected Improvements:
- ✅ Native account picker appears reliably
- ✅ No Safari browser opening
- ✅ Works on Codemagic CI/CD builds
- ✅ Consistent behavior across environments
- ✅ Reduced authentication friction
- ✅ Better user experience

---

## DEPLOYMENT WORKFLOW

### Local Testing:
```bash
# 1. Update web app code (see above)
# 2. Build and test locally
npm run ios
# 3. Verify native picker works
```

### Codemagic CI/CD:
```yaml
# codemagic.yaml should work without changes
# The community plugin auto-registers
# No special build configuration needed
```

### Push to Production:
```bash
git add .
git commit -m "Migrate to community Google Auth plugin"
git push origin main
```

Codemagic will automatically:
1. Install `@codetrix-studio/capacitor-google-auth`
2. Run `npx cap sync ios`
3. Build with plugin registered
4. Native auth will work in production build

---

## NEXT STEPS

1. **Update your web application** at `https://app.my-coach-finder.com`
   - Add the JavaScript code from Option A or B above
   - Import the plugin
   - Initialize on app load
   - Update button click handling

2. **Test locally**
   - Build iOS app
   - Verify diagnostic alerts
   - Test Google sign-in button
   - Confirm native picker appears

3. **Deploy to Codemagic**
   - Commit and push changes
   - Monitor build logs
   - Download TestFlight build
   - Test on physical device

4. **Monitor production**
   - Track authentication success rates
   - Check for error logs
   - Monitor user feedback

---

## SUPPORT RESOURCES

**Community Plugin Documentation:**
- GitHub: https://github.com/CodetrixStudio/CapacitorGoogleAuth
- NPM: https://www.npmjs.com/package/@codetrix-studio/capacitor-google-auth

**Capacitor Documentation:**
- iOS Configuration: https://capacitorjs.com/docs/ios/configuration
- Plugin Development: https://capacitorjs.com/docs/plugins

**Google Sign-In:**
- iOS Integration: https://developers.google.com/identity/sign-in/ios

---

**Migration Status:** ✅ Backend Complete | 🔴 Frontend Update Required
**Next Action:** Update web app code to use community plugin API
**Expected Result:** Native Google picker on all iOS builds (local + CI/CD)
