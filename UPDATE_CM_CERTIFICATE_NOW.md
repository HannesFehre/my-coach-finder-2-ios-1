# 🚨 URGENT: Update CM_CERTIFICATE in Codemagic

## The Problem
Your build is failing because the `CM_CERTIFICATE` variable in Codemagic still contains the OLD certificate that requires password `MyCoachFinder2024!` (with exclamation mark).

## The Solution
You need to update the `CM_CERTIFICATE` variable with the NEW certificate that uses password `MyCoachFinder2024` (NO exclamation mark).

## Steps to Fix:

### 1. Copy the New Certificate Value
The new certificate base64 value is in: `certificates/ios_distribution_simple_base64.txt`

It starts with:
```
MIIMfwIBAzCCDDUGCSqGSIb3DQEHAaCCDCYEggwiMIIMHjCCBpIGCSqGSIb3...
```

And ends with:
```
...+i3nGyyYxzElMCMGCSqGSIb3DQEJFTEWBBQcGu/wiKJdcKpH/DE9o/clIcCPKzBBMDEwDQYJYIZIAWUDBAIBBQAEIGHk8khm7+a9r/Vh2dyeqW0BJgbJSOUheEmXE2lJFY/RBAgiYtEljMa0hgICCAA=
```

**Length:** 4,272 characters (one long line, NO line breaks)

### 2. Update in Codemagic

1. Go to: https://codemagic.io/apps
2. Select: **my-coach-finder-2-ios-1**
3. Navigate to: **Environment variables** → **`ios_signing` group**
4. Find: **`CM_CERTIFICATE`**
5. **DELETE** the old value completely
6. **PASTE** the entire content from `certificates/ios_distribution_simple_base64.txt` (4,272 characters, one line)
7. Make sure **"Secure"** checkbox is checked ✓
8. **SAVE** the environment group

### 3. Verify All Variables

Make sure these are all correct:

| Variable | Value |
|----------|-------|
| `CM_CERTIFICATE` | *4,272 characters from ios_distribution_simple_base64.txt* |
| `CM_CERTIFICATE_PASSWORD` | `MyCoachFinder2024` (no exclamation mark!) |
| `CM_PROVISIONING_PROFILE` | *Your existing base64 provisioning profile* |

### 4. The Debug Will Tell You

The workflow now includes debugging that will tell you EXACTLY which certificate you're using:
- ✓ If you see "Certificate matches password: MyCoachFinder2024" → Good!
- ⚠️ If you see "ERROR: You're using the OLD certificate!" → Update CM_CERTIFICATE

## Quick Copy Command

If you're on the server, you can get the value with:
```bash
cat /home/liz/Desktop/Module/MyCoachFinder/app/appel/certificates/ios_distribution_simple_base64.txt
```

Copy the ENTIRE output (one long line) and paste it into the `CM_CERTIFICATE` field in Codemagic.

---

⚠️ **IMPORTANT**: The certificate value must be ONE LONG LINE with NO spaces or line breaks!