# Google OAuth Button Not Triggering - Fixed

## What Was Wrong

The button wasn't triggering the native Google SDK because:
1. **Script injection delay**: 0.5 second delay meant scripts loaded too late
2. **Single-phase interception**: Only capture phase, some frameworks block it
3. **Limited detection**: Only checked href, not CSS classes
4. **Frame restrictions**: Scripts only ran on main frame, not iframes

## What I Fixed (Commit: 9c4ec6d)

### 1. Immediate Script Injection
```swift
// BEFORE: DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)
// AFTER:  DispatchQueue.main.async  // Immediate!
```

### 2. Dual-Phase Click Interception
- **Capture Phase**: Runs FIRST, before any other handlers
- **Bubble Phase**: Backup if capture phase is blocked
- Both phases intercept the same button patterns

### 3. Multiple Detection Methods
```javascript
// Method 1: Check href attribute
if(href.includes('/auth/google/login'))

// Method 2: Check CSS class
if(className.includes('oauth-btn'))
```

### 4. All Frames Supported
```swift
// BEFORE: forMainFrameOnly: true
// AFTER:  forMainFrameOnly: false  // Works in iframes too
```

### 5. Clear & Re-inject Scripts
```swift
// Prevents duplicate scripts from multiple loads
webView.configuration.userContentController.removeAllUserScripts()
```

### 6. Document Start + End Scripts
- **Start Script**: Loads immediately when page starts loading
- **End Script**: Full functionality when DOM is ready

## How to Test

### 1. Build and Run
```bash
npm run ios
# OR open in Xcode and build
```

### 2. Enable Safari Web Inspector
- Connect iPhone to Mac
- Safari → Develop → [Your iPhone] → [App WebView]
- Open Console tab

### 3. Navigate to Login Page
Go to any page with the Google OAuth button

### 4. Watch for Version Badge
Look for top-right corner badge:
```
iOS v1.1.13 [NativeAuth Ready]
```

If you see this, the script is loaded!

### 5. Check Console Output
When page loads, you should see:
```
[iOS] Early script loaded at document start
[Native Bridge iOS] Auto-injecting on page load
[iOS App Version] 1.1.13 (Build X)
[iOS] Capacitor Plugins available: ["NativeAuth", "Browser", ...]
[iOS] Adding click interceptor (CAPTURE phase)...
[iOS] ✅ Click listener added (CAPTURE phase)
[iOS] Adding backup click interceptor (BUBBLE phase)...
[iOS] ✅ Backup listener added (BUBBLE phase)
```

### 6. Click the Google OAuth Button
You should see:
```
[iOS] 🔍 Click detected: {tag: "SPAN", className: "...", id: ""}
[iOS] ✅✅✅ INTERCEPTED Google OAuth: {href: "/auth/google/login?return_url=...", className: "oauth-btn", method: "href"}
[iOS] Return URL extracted: /coach/dashboard
[iOS] 🚀 _handleGoogleSignIn called with returnUrl: /coach/dashboard
[iOS] ✅ Calling native Google Sign-In...
```

Then the **native Google account picker should appear** (NOT Safari).

## Troubleshooting

### Issue: No Console Logs at All
**Cause**: Scripts not loading
**Fix**:
1. Check Safari Web Inspector is connected
2. Verify app is loading https://app.my-coach-finder.com
3. Rebuild the app completely (clean build folder)

### Issue: Scripts Load But Click Not Detected
**Cause**: Click not reaching event listeners
**Solution**: Check console for `🔍 Click detected` messages
- If you see this but no interception: CSS class name might be different
- If you don't see this: Another framework is blocking all clicks

### Issue: "NativeAuth plugin not found"
**Cause**: Plugin not registered with Capacitor
**Fix**:
1. Check NativeAuthPlugin.swift is in Xcode project
2. Verify it's in the target's "Compile Sources"
3. Clean build folder and rebuild

### Issue: Native Picker Appears But Backend Fails
**Cause**: Backend endpoint issue
**Solution**: Check console for:
```
[iOS] Backend error: 401 (or other status)
```
Verify backend endpoint: `https://app.my-coach-finder.com/auth/google/native`

### Issue: Safari Opens Instead of Native Picker
**Cause**: Event not intercepted
**Solution**:
1. Check for `✅✅✅ INTERCEPTED` message in console
2. If missing, button HTML might not match expected patterns
3. Add breakpoint in shouldOverrideLoad to see if it's called

## Manual Testing Checklist

- [ ] Version badge appears on screen
- [ ] Console shows script loading messages
- [ ] Console shows "Click listener added" for both phases
- [ ] Clicking button logs `🔍 Click detected`
- [ ] Click logs show `✅✅✅ INTERCEPTED`
- [ ] Native Google picker appears (NOT Safari)
- [ ] Can select Google account
- [ ] After auth, redirects to /coach/dashboard
- [ ] Token saved in localStorage
- [ ] User data saved in localStorage

## Debug Commands

### Check if plugin is compiled:
```bash
grep -r "NativeAuthPlugin" ios/App/App.xcodeproj/
```

### View console logs on device:
```bash
# Connect device and run:
idevicesyslog | grep "NativeAuth"
```

### Check Capacitor plugins at runtime:
Open Safari Web Inspector Console and run:
```javascript
console.log(Object.keys(window.Capacitor.Plugins));
// Should include "NativeAuth"
```

### Manually trigger sign-in:
In Safari Web Inspector Console:
```javascript
window._handleGoogleSignIn('/coach/dashboard');
```

## Expected Behavior

✅ **CORRECT**:
1. Click button
2. Native Google account picker appears INSIDE the app
3. Select account
4. App authenticates and redirects

❌ **WRONG**:
1. Click button
2. Safari browser opens
3. Google login page in Safari
4. Must enter credentials manually

## Files Modified

1. **ios/App/App/NativeAuthPlugin.swift**
   - Immediate script injection (no delay)
   - Dual-phase click interception
   - CSS class detection
   - All frames support
   - Enhanced logging

## Next Steps If Still Not Working

1. **Check button HTML**: Share the actual HTML from the web page
2. **Capture network traffic**: See if any redirects happen
3. **Test with simple button**: Create a test page with just the button
4. **Check for CSP**: Content Security Policy might block scripts
5. **Try different URL**: Test with direct link vs query parameters

## Contact/Debug Info

When reporting issues, include:
- Safari Web Inspector console output (full log)
- Screenshot of the button in the app
- iOS version
- App version from badge
- Whether you see "NativeAuth" in available plugins

---

Last Updated: 2025-10-28
Commit: 9c4ec6d
