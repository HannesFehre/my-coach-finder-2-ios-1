# Codemagic Environment Variables Setup

## Files Created

All files are located in: `/home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/`

- `ios_distribution.p12` - App Store Distribution Certificate
- `ios_distribution_p12_base64.txt` - Certificate encoded for Codemagic (4,272 chars)
- `My_Coach_Finder_App_Store.mobileprovision` - App Store Provisioning Profile
- `appstore_profile_base64.txt` - Profile encoded for Codemagic (16,288 chars)

**Certificate Password:** `MyCoachFinder2024!`

---

## Codemagic Environment Variables to Add

Go to: https://codemagic.io/apps → Select your app → Environment variables

### Create/Update Environment Group: `ios_signing`

Add these 3 variables for App Store builds:

### 1. CM_CERTIFICATE_APPSTORE
- **Type:** Secure (check the box)
- **Value:** Copy entire content from `ios_distribution_p12_base64.txt`
- **File:** `/home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/ios_distribution_p12_base64.txt`
- **Characters:** 4,272

**To copy:**
```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/ios_distribution_p12_base64.txt
```

### 2. CM_CERTIFICATE_PASSWORD_APPSTORE
- **Type:** Secure (check the box)
- **Value:** `MyCoachFinder2024!`

### 3. CM_PROVISIONING_PROFILE_APPSTORE
- **Type:** Secure (check the box)
- **Value:** Copy entire content from `appstore_profile_base64.txt`
- **File:** `/home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/appstore_profile_base64.txt`
- **Characters:** 16,288

**To copy:**
```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/appstore_profile_base64.txt
```

---

## Workflow Added to codemagic.yaml

✅ **ios-production** workflow has been added (line 64-131)

**Key differences from development build:**
- Distribution type: `app_store` (not development)
- Automatically uploads to TestFlight after build
- Increments build number automatically
- Uses App Store provisioning profile

---

## How to Trigger App Store Build

### Option 1: Web Dashboard
1. Go to: https://codemagic.io/apps
2. Open your app
3. Click **"Start new build"**
4. Select workflow: **`ios-production`** ← Important!
5. Select branch: `main`
6. Click **"Start new build"**
7. Wait ~15-20 minutes
8. Build automatically uploads to TestFlight

### Option 2: After Git Push (Auto-trigger)
You can configure Codemagic to automatically trigger `ios-production` builds on push to `main` branch.

---

## What Happens When You Build

1. ✅ Codemagic builds the iOS app
2. ✅ Signs with App Store certificate
3. ✅ Creates `.ipa` file
4. ✅ **Automatically uploads to App Store Connect**
5. ✅ **Automatically submits to TestFlight**
6. ✅ You receive email notification

---

## After First Build

1. Go to App Store Connect: https://appstoreconnect.apple.com/
2. Select your app: **My Coach Finder**
3. Go to **TestFlight** tab
4. You'll see the new build
5. Add internal/external testers
6. Distribute for testing

---

## To Submit to App Store (Public Release)

1. In App Store Connect, go to your app
2. Create new version
3. Select the TestFlight build
4. Fill in app metadata (description, screenshots, etc.)
5. Submit for review
6. Wait for Apple approval (~1-3 days)
7. Release to App Store

---

## Important Notes

⚠️ **Keep these files safe and NEVER commit to git:**
- `ios_distribution.key` - Private key
- `ios_distribution.p12` - Certificate
- `*.mobileprovision` - Provisioning profiles
- `*_base64.txt` - Encoded credentials

✅ These are already in `.gitignore` - you're safe!

---

## Troubleshooting

### "No provisioning profile found"
- Verify `CM_PROVISIONING_PROFILE_APPSTORE` is set in Codemagic
- Check the base64 string is complete (16,288 characters)

### "Certificate error"
- Verify `CM_CERTIFICATE_APPSTORE` is set
- Verify `CM_CERTIFICATE_PASSWORD_APPSTORE` is `MyCoachFinder2024!`

### "App Store Connect upload failed"
- Verify App Store Connect API credentials are set
- Check app exists in App Store Connect with bundle ID `MyCoachFinder`

---

## Next Steps

1. ✅ Add the 3 environment variables to Codemagic
2. ✅ Push `codemagic.yaml` changes to GitHub
3. ✅ Trigger `ios-production` build
4. ✅ Wait for automatic upload to TestFlight
5. ✅ Test the build on TestFlight
6. ✅ Submit to App Store when ready

---

**Created:** November 1, 2025  
**Status:** Ready to configure in Codemagic
