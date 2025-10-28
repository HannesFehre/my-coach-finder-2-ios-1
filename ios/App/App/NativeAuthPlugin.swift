import Foundation
import Capacitor
import GoogleSignIn
import WebKit

@objc(NativeAuthPlugin)
public class NativeAuthPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeAuthPlugin"
    public let jsName = "NativeAuth"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signInWithGoogle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "signOut", returnType: CAPPluginReturnPromise)
    ]

    private let googleClientId = "353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com"

    override public func load() {
        NSLog("[NativeAuth] ✅ Plugin loaded successfully")

        // Inject JavaScript using WKUserScript to run on EVERY page load
        // Do this immediately, no delay
        DispatchQueue.main.async {
            NSLog("[NativeAuth] Setting up WKUserScript for automatic injection...")
            self.setupUserScript()
        }
    }

    private func setupUserScript() {
        guard let webView = self.bridge?.webView else {
            NSLog("[NativeAuth] ❌ WebView not available")
            return
        }

        // Get app version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let scriptSource = """
        (function(){
            if(!window.Capacitor){
                console.error('[iOS] Capacitor not found!');
                return;
            }
            console.log('[Native Bridge iOS] Auto-injecting on page load');
            console.log('[iOS App Version] \(version) (Build \(build))');
            console.log('[iOS] Capacitor Plugins available:', Object.keys(window.Capacitor.Plugins||{}));

            // Add visible version overlay
            function addVersionBadge(){
                if(!document.getElementById('ios-version-badge')){
                    const versionDiv = document.createElement('div');
                    versionDiv.id = 'ios-version-badge';
                    versionDiv.textContent = 'iOS v\(version).\(build) [NativeAuth Ready]';
                    versionDiv.style.cssText = 'position:fixed;top:10px;right:10px;background:rgba(0,0,0,0.7);color:#fff;padding:5px 10px;border-radius:5px;font-size:12px;font-family:monospace;z-index:999999;';
                    if(document.body){
                        document.body.appendChild(versionDiv);
                    }else{
                        setTimeout(addVersionBadge, 100);
                    }
                }
            }
            if(document.readyState === 'loading'){
                document.addEventListener('DOMContentLoaded', addVersionBadge);
            }else{
                addVersionBadge();
            }

            // Override window.open to keep navigation in WebView
            if(!window._openOverridden){
                const originalOpen = window.open;
                window.open = function(url, target, features) {
                    if(url && url.includes('my-coach-finder.com')){
                        console.log('[iOS] Intercepting window.open, keeping in WebView:', url);
                        return originalOpen.call(this, url, '_self', features);
                    }
                    return originalOpen.call(this, url, target, features);
                };
                window._openOverridden = true;
            }

            // Google Sign-In Handler Function
            window._handleGoogleSignIn = async function(returnUrl) {
                console.log('[iOS] 🚀 _handleGoogleSignIn called with returnUrl:', returnUrl);

                // Check plugin availability
                if(!window.Capacitor?.Plugins?.NativeAuth){
                    console.error('[iOS] ❌ NativeAuth plugin not found!');
                    alert('Error: NativeAuth plugin not loaded. Available: ' + Object.keys(window.Capacitor?.Plugins||{}).join(', '));
                    return;
                }

                console.log('[iOS] ✅ Calling native Google Sign-In...');

                try{
                    const result = await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();
                    console.log('[iOS] Sign-in result:', JSON.stringify(result));

                    if(result?.idToken){
                        const backendUrl = 'https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken);
                        console.log('[iOS] Sending token to backend...');

                        const response = await fetch(backendUrl,{
                            method:'POST',
                            headers:{'Content-Type':'application/json'}
                        });

                        if(response.ok){
                            const data = await response.json();
                            console.log('[iOS] ✅ Backend authentication successful');
                            localStorage.setItem('token',data.access_token||data.token);
                            localStorage.setItem('user',JSON.stringify(data.user||{}));

                            const redirectUrl = returnUrl
                                ? 'https://app.my-coach-finder.com' + returnUrl
                                : 'https://app.my-coach-finder.com/';
                            console.log('[iOS] Redirecting to:', redirectUrl);
                            window.location.href = redirectUrl;
                        }else{
                            const errorText = await response.text();
                            console.error('[iOS] Backend error:', response.status, errorText);
                            alert('Authentication failed: ' + response.status);
                        }
                    }else{
                        console.error('[iOS] No ID token received');
                        alert('No ID token received from Google');
                    }
                }catch(err){
                    console.error('[iOS] Sign-in error:', err);
                    alert('Sign-in error: ' + err.message);
                }
            };

            // STRATEGY 1: Intercept ALL clicks in CAPTURE phase
            if(!window._clickListenerAdded){
                console.log('[iOS] Adding click interceptor (CAPTURE phase)...');

                document.addEventListener('click',function(e){
                    console.log('[iOS] 🔍 Click detected:', {
                        tag: e.target.tagName,
                        className: e.target.className,
                        id: e.target.id
                    });

                    let el = e.target;

                    // Traverse up to 10 parent elements
                    for(let i=0; i<10 && el; i++){
                        const href = el.getAttribute && el.getAttribute('href');
                        const className = el.className || '';

                        // Check if it's a Google OAuth link
                        const isGoogleAuth = href && (
                            href.includes('/auth/google/login') ||
                            href.includes('auth/google/login')
                        );

                        // ALSO check for oauth-btn class
                        const isOAuthBtn = className.includes && className.includes('oauth-btn');

                        if(isGoogleAuth || isOAuthBtn){
                            console.log('[iOS] ✅✅✅ INTERCEPTED Google OAuth:', {
                                href: href,
                                className: className,
                                method: isGoogleAuth ? 'href' : 'class'
                            });

                            // CRITICAL: Stop ALL propagation IMMEDIATELY
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();

                            // Extract return_url
                            let returnUrl = null;
                            if(href){
                                try{
                                    const url = new URL(href, window.location.origin);
                                    returnUrl = url.searchParams.get('return_url');
                                    console.log('[iOS] Return URL extracted:', returnUrl);
                                }catch(err){
                                    console.log('[iOS] Could not parse return_url:', err.message);
                                }
                            }

                            // Call handler
                            window._handleGoogleSignIn(returnUrl);
                            return false;
                        }
                        el = el.parentElement;
                    }
                },true); // CAPTURE = true

                window._clickListenerAdded = true;
                console.log('[iOS] ✅ Click listener added (CAPTURE phase)');
            }

            // STRATEGY 2: Also add listener on BUBBLE phase as backup
            if(!window._bubbleListenerAdded){
                console.log('[iOS] Adding backup click interceptor (BUBBLE phase)...');

                document.addEventListener('click',function(e){
                    let el = e.target;
                    for(let i=0; i<10 && el; i++){
                        const href = el.getAttribute && el.getAttribute('href');
                        const className = el.className || '';

                        if((href && (href.includes('/auth/google/login') || href.includes('auth/google/login'))) ||
                           (className.includes && className.includes('oauth-btn'))){
                            console.log('[iOS] 🔄 BUBBLE phase intercepted (capture missed it)');
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();

                            let returnUrl = null;
                            if(href){
                                try{
                                    const url = new URL(href, window.location.origin);
                                    returnUrl = url.searchParams.get('return_url');
                                }catch(err){}
                            }

                            window._handleGoogleSignIn(returnUrl);
                            return false;
                        }
                        el = el.parentElement;
                    }
                },false); // BUBBLE = false

                window._bubbleListenerAdded = true;
                console.log('[iOS] ✅ Backup listener added (BUBBLE phase)');
            }
        })();
        """

        // Clear any existing scripts first to avoid duplicates
        webView.configuration.userContentController.removeAllUserScripts()

        // Add at document END for main functionality
        let endScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(endScript)

        // Also add a simpler version at document START for early interception
        let startScriptSource = """
        console.log('[iOS] Early script loaded at document start');
        window._nativeAuthEarlyLoad = true;
        """
        let startScript = WKUserScript(source: startScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(startScript)

        NSLog("[NativeAuth] ✅ WKUserScripts added (start + end) - will run on every page load")
    }

    // MARK: - Capacitor Navigation Override

    @objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
        guard let url = navigationAction.request.url else {
            NSLog("[NativeAuth] shouldOverrideLoad: No URL in navigation action")
            return nil
        }

        let urlString = url.absoluteString
        NSLog("[NativeAuth] shouldOverrideLoad called for URL: %@", urlString)

        // Block Google OAuth redirects to accounts.google.com - our native sign-in handles this
        if urlString.contains("accounts.google.com") {
            NSLog("[NativeAuth] ❌ Blocking Google OAuth URL: %@", urlString)
            // Return true to prevent loading (JavaScript will handle it)
            return true
        }

        // Keep all app domain URLs in WebView (don't open in Safari)
        if urlString.contains("app.my-coach-finder.com") {
            NSLog("[NativeAuth] ✅ Allowing app domain in WebView: %@", urlString)
            // Return false to allow loading in WebView
            return false
        }

        // For all other URLs, use Capacitor's default behavior
        NSLog("[NativeAuth] Using default behavior for URL: %@", urlString)
        return nil
    }

    @objc func signInWithGoogle(_ call: CAPPluginCall) {
        guard let presentingViewController = self.bridge?.viewController else {
            call.reject("Unable to get view controller")
            return
        }

        let config = GIDConfiguration(clientID: googleClientId)
        GIDSignIn.sharedInstance.configuration = config

        // Sign out first to always show account picker
        GIDSignIn.sharedInstance.signOut()

        DispatchQueue.main.async {
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { signInResult, error in
                if let error = error {
                    call.reject("Google Sign-In failed: \(error.localizedDescription)")
                    return
                }

                guard let user = signInResult?.user,
                      let idToken = user.idToken?.tokenString else {
                    call.reject("Unable to get ID token")
                    return
                }

                let email = user.profile?.email ?? ""
                let displayName = user.profile?.name ?? ""
                let photoUrl = user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""

                var result = JSObject()
                result["idToken"] = idToken
                result["email"] = email
                result["displayName"] = displayName
                result["photoUrl"] = photoUrl

                call.resolve(result)
            }
        }
    }

    @objc func signOut(_ call: CAPPluginCall) {
        GIDSignIn.sharedInstance.signOut()

        var result = JSObject()
        result["success"] = true
        call.resolve(result)
    }
}
