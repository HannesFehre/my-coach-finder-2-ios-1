package com.mycoachfinder.app;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        // Register the native auth plugin
        registerPlugin(NativeAuthPlugin.class);

        super.onCreate(savedInstanceState);

        // Get WebView settings
        WebSettings webSettings = this.bridge.getWebView().getSettings();

        // Set custom user agent to appear as Chrome browser (not WebView)
        // This allows OAuth providers to work properly
        String currentUA = webSettings.getUserAgentString();
        String customUA = currentUA.replace("wv", "").replace("; ", " Chrome/120.0.0.0 Mobile Safari/537.36; ");
        webSettings.setUserAgentString(customUA);

        // Enable all necessary WebView features for full OAuth support
        webSettings.setJavaScriptEnabled(true);
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setDatabaseEnabled(true);
        webSettings.setSupportMultipleWindows(false);
        webSettings.setAllowFileAccess(true);
        webSettings.setAllowContentAccess(true);
        webSettings.setLoadsImagesAutomatically(true);
        webSettings.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);

        // Enable third-party cookies (required for OAuth)
        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.setAcceptCookie(true);
        cookieManager.setAcceptThirdPartyCookies(this.bridge.getWebView(), true);

        // Keep all navigation within the app - fully native experience
        this.bridge.getWebView().setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                // Everything stays in the WebView - no external browsers
                view.loadUrl(url);
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                // Inject native auth bridge into the loaded page
                injectNativeAuthBridge(view);
                // Inject push notification registration script
                injectPushNotifications(view);
            }
        });

        // Handle deep links if app was opened from external source
        handleDeepLink(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleDeepLink(intent);
    }

    private void handleDeepLink(Intent intent) {
        if (intent != null && Intent.ACTION_VIEW.equals(intent.getAction())) {
            Uri data = intent.getData();
            if (data != null) {
                // Deep link received - load in WebView
                String url = data.toString();
                this.bridge.getWebView().loadUrl(url);
            }
        }
    }

    private void injectNativeAuthBridge(WebView webView) {
        String nativeAuthScript =
            "(function(){" +
            "if(!window.Capacitor)return;" +
            "console.log('[Native Bridge] Injecting native auth and session manager');" +

            // Session Manager with fallback
            "window.SessionManager={" +
            "checkAndRestore:async function(){" +
            "try{" +
            "console.log('[Session] Checking for saved session...');" +
            "if(!window.Capacitor.Plugins||!window.Capacitor.Plugins.Preferences){" +
            "console.log('[Session] Preferences plugin not available, using localStorage only');" +
            "return false;" +
            "}" +
            "const Prefs=window.Capacitor.Plugins.Preferences;" +
            "const token=await Prefs.get({key:'auth_token'});" +
            "const user=await Prefs.get({key:'auth_user'});" +
            "if(token.value&&user.value){" +
            "console.log('[Session] Restoring saved session');" +
            "localStorage.setItem('token',token.value);" +
            "localStorage.setItem('user',user.value);" +
            "return true;" +
            "}" +
            "}catch(e){console.error('[Session] Error restoring:',e);}" +
            "return false;" +
            "}," +
            "save:async function(token,user){" +
            "try{" +
            "console.log('[Session] Saving session to localStorage');" +
            "localStorage.setItem('token',token);" +
            "localStorage.setItem('user',user);" +
            "if(window.Capacitor.Plugins&&window.Capacitor.Plugins.Preferences){" +
            "console.log('[Session] Also saving to persistent storage');" +
            "const Prefs=window.Capacitor.Plugins.Preferences;" +
            "await Prefs.set({key:'auth_token',value:token});" +
            "await Prefs.set({key:'auth_user',value:user});" +
            "console.log('[Session] Saved successfully');" +
            "}else{" +
            "console.log('[Session] Preferences not available, localStorage only');" +
            "}" +
            "}catch(e){console.error('[Session] Error saving:',e);}" +
            "}," +
            "clear:async function(){" +
            "try{" +
            "console.log('[Session] Clearing session');" +
            "localStorage.removeItem('token');" +
            "localStorage.removeItem('user');" +
            "if(window.Capacitor.Plugins&&window.Capacitor.Plugins.Preferences){" +
            "const Prefs=window.Capacitor.Plugins.Preferences;" +
            "await Prefs.remove({key:'auth_token'});" +
            "await Prefs.remove({key:'auth_user'});" +
            "}" +
            "}catch(e){console.error('[Session] Error clearing:',e);}" +
            "}" +
            "};" +

            // Auto-restore session on login pages OR detect logout
            "setTimeout(async function(){" +
            "const currentUrl=window.location.href;" +
            "const isLoginPage=currentUrl.includes('/auth/login')||currentUrl.includes('/auth/signup');" +
            "const hasToken=localStorage.getItem('token');" +

            "if(isLoginPage){" +
            "if(hasToken){" +
            "console.log('[Session] On login page with token, attempting auto-login');" +
            "const restored=await window.SessionManager.checkAndRestore();" +
            "if(restored){" +
            "console.log('[Session] Auto-login successful, redirecting');" +
            "window.location.href='https://app.my-coach-finder.com/';" +
            "}" +
            "}else{" +
            "console.log('[Session] On login page without token, clearing any persisted session');" +
            "await window.SessionManager.clear();" +
            "}" +
            "}else{" +
            "const token=localStorage.getItem('token');" +
            "const user=localStorage.getItem('user');" +
            "if(token&&user){" +
            "await window.SessionManager.save(token,user);" +
            "}" +
            "}" +
            "},500);" +

            // Click event listener for Google Sign-In ONLY
            "document.addEventListener('click',async function(e){" +
            "let el=e.target;" +
            "for(let i=0;i<5&&el;i++){" +
            "if(!el.tagName)break;" +
            "const tag=el.tagName.toLowerCase();" +
            "if(tag!=='button'&&tag!=='a'&&tag!=='div'&&tag!=='span'){el=el.parentElement;continue;}" +
            "const txt=(el.textContent||'').toLowerCase().trim();" +
            "const cls=String(el.className||'').toLowerCase();" +
            "const id=String(el.id||'').toLowerCase();" +
            "const dataProvider=String(el.getAttribute('data-provider')||'').toLowerCase();" +
            "const href=String(el.getAttribute('href')||'').toLowerCase();" +

            // Check for Google OAuth redirect link
            "const isGoogleAuthLink=(tag==='a'&&href.includes('/auth/google/login'));" +

            "if(isGoogleAuthLink){" +
            "console.log('[Native Bridge] Intercepted Google OAuth link:',href);" +
            "e.preventDefault();" +
            "e.stopPropagation();" +

            // Extract return_url from href
            "let returnUrl='https://app.my-coach-finder.com/';" +
            "const fullHref=el.getAttribute('href')||'';" +
            "const returnMatch=fullHref.match(/return_url=([^&]+)/);" +
            "if(returnMatch){" +
            "returnUrl=decodeURIComponent(returnMatch[1]);" +
            "if(!returnUrl.startsWith('http')){" +
            "returnUrl='https://app.my-coach-finder.com'+returnUrl;" +
            "}" +
            "console.log('[Native Bridge] Will redirect to:',returnUrl);" +
            "}" +

            // Call native Google Sign-In
            "console.log('[Native Bridge] Triggering native Google Sign-In...');" +
            "try{" +
            "const result=await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();" +
            "console.log('[Native Bridge] Native auth result:',result);" +

            "if(result&&result.idToken){" +
            "console.log('[Native Bridge] Got ID token, sending to backend...');" +
            "const response=await fetch('https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken),{" +
            "method:'POST'," +
            "headers:{'Content-Type':'application/json'}" +
            "});" +
            "console.log('[Native Bridge] Backend response status:',response.status);" +

            "if(response.ok){" +
            "const data=await response.json();" +
            "console.log('[Native Bridge] Login successful, token:',data.access_token?'present':'missing');" +
            "const token=data.access_token||data.token;" +
            "const user=JSON.stringify(data.user||{});" +
            "localStorage.setItem('token',token);" +
            "localStorage.setItem('user',user);" +
            "await window.SessionManager.save(token,user);" +
            "console.log('[Native Bridge] Redirecting to:',returnUrl);" +
            "window.location.href=returnUrl;" +
            "}else{" +
            "const errorText=await response.text();" +
            "console.error('[Native Bridge] Backend returned error:',response.status,errorText);" +
            "alert('Login failed: '+errorText);" +
            "}" +
            "}else{" +
            "console.log('[Native Bridge] No ID token received, user may have cancelled');" +
            "}" +
            "}catch(err){" +
            "console.error('[Native Bridge] Error during native sign-in:',err);" +
            "alert('Login error: '+err.message);" +
            "}" +

            "return false;" +
            "}" +

            "el=el.parentElement;" +
            "}" +
            "},true);" +

            "console.log('[Native Bridge] Native auth bridge active');" +
            "})();";

        webView.evaluateJavascript(nativeAuthScript, null);
    }

    private void injectPushNotifications(WebView webView) {
        // Register for push notifications
        String pushNotificationScript =
            "(function(){" +
            "if(!window.Capacitor||!window.Capacitor.Plugins.PushNotifications)return;" +
            "console.log('[Push] Initializing push notifications');" +
            "const PushNotifications=window.Capacitor.Plugins.PushNotifications;" +
            "PushNotifications.checkPermissions().then(status=>{" +
            "console.log('[Push] Permission status:',status.receive);" +
            "if(status.receive==='granted'){" +
            "console.log('[Push] Permission already granted, registering...');" +
            "PushNotifications.register();" +
            "return;" +
            "}" +
            "console.log('[Push] Requesting permissions...');" +
            "PushNotifications.requestPermissions().then(result=>{" +
            "console.log('[Push] Permission result:',result.receive);" +
            "if(result.receive==='granted'){" +
            "console.log('[Push] Permission granted, registering...');" +
            "PushNotifications.register();" +
            "}" +
            "});" +
            "});" +
            "PushNotifications.addListener('registration',token=>{" +
            "console.log('[Push] Token registered:',token.value);" +
            "localStorage.setItem('fcm_token',token.value);" +
            "localStorage.setItem('device_platform','android');" +
            "console.log('[Push] Token saved to localStorage');" +
            "});" +
            "PushNotifications.addListener('registrationError',error=>{" +
            "console.error('[Push] Registration error:',error);" +
            "});" +
            "})();";

        webView.evaluateJavascript(pushNotificationScript, null);
    }
}
