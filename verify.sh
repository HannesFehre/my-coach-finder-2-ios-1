#!/bin/bash

echo "╔════════════════════════════════════════════════════════╗"
echo "║   GOOGLE AUTH IMPLEMENTATION VERIFICATION              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Check function
check() {
    local name="$1"
    local command="$2"
    local expected="$3"

    echo -n "Checking: $name... "

    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAIL++))
        if [ -n "$expected" ]; then
            echo "   Expected: $expected"
        fi
    fi
}

warn() {
    local message="$1"
    echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
    ((WARN++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 1: WEB APP CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check "Web app accessible" \
    "curl -s -o /dev/null -w '%{http_code}' https://app.my-coach-finder.com/go | grep -q '200'"

check "Backend endpoint exists" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST https://app.my-coach-finder.com/auth/google/native | grep -qE '400|401|200'"

check "OAuth page exists" \
    "curl -s -o /dev/null -w '%{http_code}' https://app.my-coach-finder.com/auth/google/login | grep -qE '200|302'"

echo ""
echo "Checking if web app has GoogleAuth integration..."
if curl -s https://app.my-coach-finder.com/go 2>/dev/null | grep -qi "GoogleAuth\|capacitor-google-auth"; then
    echo -e "${GREEN}✅ PASS${NC} - Web app has plugin integration"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Web app does NOT have plugin integration"
    warn "Your web app at https://app.my-coach-finder.com needs JavaScript code"
    echo "   See: WEB_APP_INTEGRATION_REQUIRED.md"
    ((FAIL++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 2: iOS BACKEND CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check "Plugin in package.json" \
    "grep -q 'capacitor-google-auth' /home/liz/Desktop/Module/MyCoachFinder/app/appel/package.json"

check "Plugin in Podfile" \
    "grep -q 'CodetrixStudioCapacitorGoogleAuth' /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/Podfile"

echo -n "Checking for version conflict... "
if grep -q "GoogleSignIn.*7\.0" /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/Podfile; then
    echo -e "${RED}❌ CONFLICT FOUND${NC}"
    warn "Manual GoogleSignIn 7.0 in Podfile causes conflict"
    echo "   Should only have CodetrixStudioCapacitorGoogleAuth"
    ((FAIL++))
else
    echo -e "${GREEN}✅ NO CONFLICT${NC}"
    ((PASS++))
fi

check "GoogleAuth in capacitor.config.json" \
    "grep -q 'GoogleAuth' /home/liz/Desktop/Module/MyCoachFinder/app/appel/capacitor.config.json"

check "GIDClientID in Info.plist" \
    "grep -q 'GIDClientID' /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/App/Info.plist"

check "URL scheme in Info.plist" \
    "grep -q 'com.googleusercontent.apps' /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/App/Info.plist"

check "Custom plugin disabled" \
    "test -f /home/liz/Desktop/Module/MyCoachFinder/app/appel/ios/App/App/NativeAuthPlugin.swift.backup"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SECTION 3: BACKEND API CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Testing backend with dummy token..."
RESPONSE=$(curl -s -X POST "https://app.my-coach-finder.com/auth/google/native?id_token=test_token" 2>&1)
STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X POST "https://app.my-coach-finder.com/auth/google/native?id_token=test_token" 2>&1)

if echo "$STATUS" | grep -qE "400|401"; then
    echo -e "${GREEN}✅ PASS${NC} - Backend validates tokens (rejected dummy token)"
    ((PASS++))
elif echo "$STATUS" | grep -q "404"; then
    echo -e "${RED}❌ FAIL${NC} - Backend endpoint not found (404)"
    ((FAIL++))
elif echo "$STATUS" | grep -q "200"; then
    echo -e "${YELLOW}⚠️  WARNING${NC} - Backend accepted dummy token (should validate)"
    ((WARN++))
else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Unexpected status: $STATUS"
    ((WARN++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "Passed:   ${GREEN}$PASS${NC}"
echo -e "Failed:   ${RED}$FAIL${NC}"
echo -e "Warnings: ${YELLOW}$WARN${NC}"
echo ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL CHECKS PASSED - IMPLEMENTATION LOOKS GOOD!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Build iOS app: npm run ios"
    echo "2. Test button - should show native Google picker"
elif [ $FAIL -gt 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ SOME CHECKS FAILED - ACTION REQUIRED              ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Most common issue:"
    echo "  → Web app needs JavaScript integration"
    echo "  → See: WEB_APP_INTEGRATION_REQUIRED.md"
    echo ""
    echo "To fix:"
    echo "1. Add GoogleAuth code to your web app"
    echo "2. Deploy web app"
    echo "3. Rebuild iOS: npx cap sync ios && npm run ios"
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  WARNINGS FOUND - REVIEW RECOMMENDED              ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Check warnings above for details"
fi

echo ""
echo "For detailed verification guide, see: VERIFICATION_TESTS.md"
echo ""
