# Trigger Codemagic Build via API

## Quick Command to Trigger iOS Production Build

```bash
curl -H "Content-Type: application/json" \
     -H "x-auth-token: wk5PJKmmO4_V70_6ZC6VMqWptvqGep6n95F6rR6HWgA" \
     --data '{
       "appId": "68fd6f2a7e282f2bab8b9665",
       "workflowId": "ios-production",
       "branch": "main"
     }' \
     -X POST https://api.codemagic.io/builds
```

## Check Build Status

Replace `{BUILD_ID}` with the ID returned from the trigger command:

```bash
curl -H "x-auth-token: wk5PJKmmO4_V70_6ZC6VMqWptvqGep6n95F6rR6HWgA" \
     https://api.codemagic.io/builds/{BUILD_ID}
```

## List Recent Builds

```bash
curl -H "x-auth-token: wk5PJKmmO4_V70_6ZC6VMqWptvqGep6n95F6rR6HWgA" \
     https://api.codemagic.io/builds?appId=68fd6f2a7e282f2bab8b9665
```

---

## Alternative: Trigger Development Build

```bash
curl -H "Content-Type: application/json" \
     -H "x-auth-token: wk5PJKmmO4_V70_6ZC6VMqWptvqGep6n95F6rR6HWgA" \
     --data '{
       "appId": "68fd6f2a7e282f2bab8b9665",
       "workflowId": "ios-development",
       "branch": "main"
     }' \
     -X POST https://api.codemagic.io/builds
```

---

## API Key Location

**Full details:** `/home/liz/Desktop/Module/MyCoachFinder/app/appel_privat/CODEMAGIC_API_KEY.txt`

**API Key:** `wk5PJKmmO4_V70_6ZC6VMqWptvqGep6n95F6rR6HWgA`

**⚠️ NEVER commit this file to git!** (Already protected by .gitignore)

---

## Codemagic Dashboard

**URL:** https://codemagic.io/apps

**App ID:** 68fd6f2a7e282f2bab8b9665

**Repository:** github.com/HannesFehre/my-coach-finder-2-ios-1

---

Created: November 1, 2025
