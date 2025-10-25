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
            "console.log('[Session] Initializing persistent session manager');" +
            "const Prefs=window.Capacitor.Plugins.Preferences;" +
            "window.SessionManager={" +
            "checkAndRestore:async function(){" +
            "console.log('[Session] Checking for saved session...');" +
            "const token=await Prefs.get({key:'auth_token'});" +
            "const user=await Prefs.get({key:'auth_user'});" +
            "if(token.value&&user.value){" +
            "console.log('[Session] Restoring saved session');" +
            "localStorage.setItem('token',token.value);" +
            "localStorage.setItem('user',user.value);" +
            "return true;" +
            "}" +
            "return false;" +
            "}," +
            "save:async function(token,user){" +
            "console.log('[Session] Saving session');" +
            "await Prefs.set({key:'auth_token',value:token});" +
            "await Prefs.set({key:'auth_user',value:user});" +
            "}," +
            "clear:async function(){" +
            "console.log('[Session] Clearing session');" +
            "await Prefs.remove({key:'auth_token'});" +
            "await Prefs.remove({key:'auth_user'});" +
            "localStorage.removeItem('token');" +
            "localStorage.removeItem('user');" +
            "}" +
            "};" +
            "setTimeout(async function(){" +
            "const currentUrl=window.location.href;" +
            "if(currentUrl.includes('/auth/login')||currentUrl.includes('/auth/signup')){" +
            "const restored=await window.SessionManager.checkAndRestore();" +
            "if(restored){" +
            "console.log('[Session] Auto-login successful, redirecting');" +
            "window.location.href='https://app.my-coach-finder.com/';" +
            "}" +
            "}else{" +
            "const token=localStorage.getItem('token');" +
            "const user=localStorage.getItem('user');" +
            "if(token&&user){" +
            "await window.SessionManager.save(token,user);" +
            "}" +
            "}" +
            "},500);" +
            "document.addEventListener('click',async function(e){" +
            "let el=e.target;" +
            "for(let i=0;i<5&&el;i++){" +
            "if(!el.tagName)break;" +
            "const tag=el.tagName.toLowerCase();" +
            "if(tag!=='button'&&tag!=='a'&&tag!=='div'&&tag!=='span'){el=el.parentElement;continue;}" +
            "const txt=(el.textContent||'').toLowerCase().trim();" +
            "const cls=String(el.className||'').toLowerCase();" +
            "const id=String(el.id||'').toLowerCase();" +
            "const href=String(el.getAttribute('href')||'').toLowerCase();" +
            "const isLogout=(txt.includes('logout')||txt.includes('sign out')||txt.includes('abmelden')||txt.includes('ausloggen')||cls.includes('logout')||id.includes('logout')||href.includes('logout')||href.includes('signout'));" +
            "if(isLogout){" +
            "console.log('[Session] Logout detected, clearing session');" +
            "await window.SessionManager.clear();" +
            "break;" +
            "}" +
            "el=el.parentElement;" +
            "}" +
            "},true);" +
            "console.log('[Session] Manager active');" +
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
