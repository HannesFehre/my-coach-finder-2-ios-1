# Codemagic Environment Variables - App Store Connect API

## Required Variables for Automatic Code Signing

Add these to Codemagic in the `ios_signing` environment group.

---

### 1. APP_STORE_CONNECT_KEY_IDENTIFIER

**Name:** `APP_STORE_CONNECT_KEY_IDENTIFIER`

**Value:** `QYXYBNUU85`

**Type:** Regular (not secure)

**Description:** The Key ID from your App Store Connect API key filename (AuthKey_QYXYBNUU85.p8)

---

### 2. APP_STORE_CONNECT_PRIVATE_KEY

**Name:** `APP_STORE_CONNECT_PRIVATE_KEY`

**Value:** Copy the entire content from:
```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/AuthKey_QYXYBNUU85.p8
```

**Type:** Secure (check the box)

**Description:** The .p8 API key file content. Should look like:
```
-----BEGIN PRIVATE KEY-----
MIGTAgE...
(multiple lines)
...
-----END PRIVATE KEY-----
```

**Characters:** ~257

---

### 3. APP_STORE_CONNECT_ISSUER_ID

**Name:** `APP_STORE_CONNECT_ISSUER_ID`

**Value:** Find this in App Store Connect

**Type:** Regular (not secure)

**Description:** UUID format like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

**How to find it:**
1. Go to: https://appstoreconnect.apple.com/access/api
2. Look for "Issuer ID" at the top of the page
3. Copy the UUID

---

## How to Add to Codemagic

1. Go to: https://codemagic.io/apps
2. Open: my-coach-finder-2-ios-1
3. Click: "Environment variables"
4. Find or create group: `ios_signing`
5. Add all 3 variables above
6. Save

---

## Remove Old Variables (No Longer Needed)

You can DELETE these (not needed with automatic signing):
- CM_CERTIFICATE
- CM_CERTIFICATE_PASSWORD
- CM_PROVISIONING_PROFILE
- CM_CERTIFICATE_APPSTORE
- CM_CERTIFICATE_PASSWORD_APPSTORE
- CM_PROVISIONING_PROFILE_APPSTORE

---

**Created:** November 1, 2025
**Status:** Ready to add to Codemagic
