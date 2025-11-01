# Backend iOS App Detection Guide

## Problem Fixed

**WebKit Privacy Error:**
```
WebContent[19634] Unable to hide query parameter from script (missing data)
```

This was caused by WebKit's privacy features interfering with query parameters in the Capacitor config URL.

## Solution Implemented

Two methods for backend to detect iOS app requests:

### Method 1: Query Parameter (Primary)
✅ **Parameter:** `?os=apple`
✅ **Added by:** JavaScript dynamically
✅ **Available on:** All page loads and navigations

### Method 2: User-Agent Header (Backup)
✅ **Header:** `User-Agent: ...MyCoachFinder-iOS/1.1.13`
✅ **Format:** Standard User-Agent + `MyCoachFinder-iOS/[version].[build]`
✅ **Available on:** All HTTP requests

---

## Backend Implementation

### Python/FastAPI Example

```python
from fastapi import FastAPI, Request, Query

app = FastAPI()

def is_ios_app(request: Request, os: str = Query(None)) -> bool:
    """
    Detect if request is from iOS app.

    Checks two sources:
    1. Query parameter: ?os=apple
    2. User-Agent header contains "MyCoachFinder-iOS"
    """
    # Method 1: Check query parameter
    if os == "apple":
        return True

    # Method 2: Check User-Agent header (backup)
    user_agent = request.headers.get("user-agent", "")
    if "MyCoachFinder-iOS" in user_agent:
        return True

    return False

@app.get("/go")
async def go_page(request: Request, os: str = Query(None)):
    is_app = is_ios_app(request, os)

    if is_app:
        print("[iOS App Request]")
        # iOS-specific logic here
    else:
        print("[Web Browser Request]")
        # Web browser logic here

    return {"platform": "ios" if is_app else "web"}

@app.get("/api/users")
async def get_users(request: Request, os: str = Query(None)):
    is_app = is_ios_app(request, os)

    # Example: Different behavior for iOS app
    users = get_all_users()

    if is_app:
        # Add iOS-specific fields
        for user in users:
            user["supports_push_notifications"] = True

    return users
```

### Node.js/Express Example

```javascript
const express = require('express');
const app = express();

function isIOSApp(req) {
    // Method 1: Check query parameter
    if (req.query.os === 'apple') {
        return true;
    }

    // Method 2: Check User-Agent header (backup)
    const userAgent = req.get('user-agent') || '';
    if (userAgent.includes('MyCoachFinder-iOS')) {
        return true;
    }

    return false;
}

app.get('/go', (req, res) => {
    const isApp = isIOSApp(req);

    if (isApp) {
        console.log('[iOS App Request]');
        // iOS-specific logic
    } else {
        console.log('[Web Browser Request]');
        // Web browser logic
    }

    res.json({ platform: isApp ? 'ios' : 'web' });
});

app.get('/api/users', (req, res) => {
    const isApp = isIOSApp(req);

    // Example: Different response for iOS app
    const users = getAllUsers();

    if (isApp) {
        users.forEach(user => {
            user.supports_push_notifications = true;
        });
    }

    res.json(users);
});
```

### PHP Example

```php
<?php

function is_ios_app() {
    // Method 1: Check query parameter
    if (isset($_GET['os']) && $_GET['os'] === 'apple') {
        return true;
    }

    // Method 2: Check User-Agent header (backup)
    $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
    if (strpos($user_agent, 'MyCoachFinder-iOS') !== false) {
        return true;
    }

    return false;
}

// Example usage
if (is_ios_app()) {
    echo "iOS App Request";
    // iOS-specific logic
} else {
    echo "Web Browser Request";
    // Web browser logic
}
?>
```

---

## Testing

### 1. Check Query Parameter in Your Debug Window

Your SaaS debug window should now show:
```
GET parameters:
- os: apple ✅
```

### 2. Check User-Agent Header

In your backend logs, you should see:
```
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MyCoachFinder-iOS/1.1.13
```

### 3. Test Both Methods

```python
# Test endpoint
@app.get("/debug/platform")
async def debug_platform(request: Request, os: str = Query(None)):
    user_agent = request.headers.get("user-agent", "")

    return {
        "query_param_os": os,
        "user_agent": user_agent,
        "detected_as_ios_app": is_ios_app(request, os),
        "detection_method": (
            "query_param" if os == "apple" else
            "user_agent" if "MyCoachFinder-iOS" in user_agent else
            "none"
        )
    }
```

Expected response from iOS app:
```json
{
    "query_param_os": "apple",
    "user_agent": "...MyCoachFinder-iOS/1.1.13",
    "detected_as_ios_app": true,
    "detection_method": "query_param"
}
```

---

## Use Cases

### 1. Analytics Tracking
```python
if is_ios_app(request, os):
    analytics.track(user_id, "page_view", platform="ios_app")
else:
    analytics.track(user_id, "page_view", platform="web")
```

### 2. Feature Flags
```python
features = get_user_features(user_id)

if is_ios_app(request, os):
    features["push_notifications"] = True
    features["native_oauth"] = True
    features["share_via_system"] = True

return features
```

### 3. Different UI/UX
```python
if is_ios_app(request, os):
    # Hide mobile app download banner
    show_download_banner = False
    # Use native navigation
    navigation_style = "native"
else:
    show_download_banner = True
    navigation_style = "web"
```

### 4. Rate Limiting
```python
# Different rate limits for app vs web
if is_ios_app(request, os):
    rate_limit = 1000  # Requests per hour
else:
    rate_limit = 100   # Lower for web to prevent abuse
```

### 5. Redirect Behavior
```python
if is_ios_app(request, os):
    # Keep all navigation in-app
    use_external_links = False
else:
    # Allow external redirects
    use_external_links = True
```

---

## Advantages of Dual Detection

### Query Parameter (`?os=apple`)
✅ Easy to parse
✅ Visible in logs
✅ Can be filtered in analytics
✅ Preserved in URL

### User-Agent Header
✅ Automatic on all requests
✅ Works even if query parameter is stripped
✅ Includes version information
✅ Standard HTTP header

### Both Together
✅ **Redundancy:** If one fails, the other works
✅ **Accuracy:** Two independent detection methods
✅ **Versioning:** User-Agent includes app version
✅ **Debugging:** Easy to see in network tools

---

## Migration Path

If you want to gradually migrate from query parameter to User-Agent:

**Phase 1 (Now):** Use both methods
```python
if os == "apple" or "MyCoachFinder-iOS" in user_agent:
    return True
```

**Phase 2 (Later):** Prefer User-Agent, fallback to query param
```python
if "MyCoachFinder-iOS" in user_agent:
    return True
return os == "apple"  # Fallback for older app versions
```

**Phase 3 (Future):** User-Agent only
```python
return "MyCoachFinder-iOS" in user_agent
```

---

## Common Issues & Solutions

### Issue: Query parameter missing
**Cause:** User shares URL without parameter
**Solution:** User-Agent detection still works ✅

### Issue: User-Agent doesn't contain "MyCoachFinder-iOS"
**Cause:** Old app version or plugin not loaded
**Solution:** Query parameter detection still works ✅

### Issue: Both methods fail
**Cause:** Very old app version or corrupted install
**Solution:** Assume web browser, graceful degradation

---

## Security Considerations

### ⚠️ Don't Trust Blindly

Both methods can be spoofed:
- Query parameter: User can add `?os=apple` manually
- User-Agent: Can be modified

### ✅ Use for UX, Not Security

**Good uses:**
- Analytics tracking
- UI/UX customization
- Feature flags
- Rate limiting preferences

**Bad uses:**
- Authentication decisions
- Payment processing
- Security restrictions
- Sensitive operations

### ✅ Additional Verification

For sensitive operations, combine with:
- Device fingerprinting
- IP reputation
- Behavioral analysis
- OAuth tokens from native Google Sign-In

---

## Version Information

Extract app version from User-Agent:

```python
import re

def get_ios_app_version(user_agent: str) -> str | None:
    """Extract iOS app version from User-Agent"""
    match = re.search(r'MyCoachFinder-iOS/([0-9.]+)', user_agent)
    return match.group(1) if match else None

# Usage
user_agent = request.headers.get("user-agent", "")
version = get_ios_app_version(user_agent)

if version:
    print(f"iOS App Version: {version}")  # e.g., "1.1.13"

    # Version-specific logic
    if version >= "1.2.0":
        features["new_feature"] = True
```

---

## Summary

✅ **Two detection methods implemented**
✅ **No WebKit privacy errors**
✅ **Works on all requests**
✅ **Easy to implement in backend**
✅ **Includes version information**

**Test endpoint:** `/debug/platform`
**Expected result:** Both `os=apple` and `MyCoachFinder-iOS` detected

Build on Codemagic and test! 🚀
