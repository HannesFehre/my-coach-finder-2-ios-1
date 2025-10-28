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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
            if(!window.Capacitor)return;
            console.log('[Native Bridge iOS] Auto-injecting on page load');
            console.log('[iOS App Version] \(version) (Build \(build))');

            // Add visible version overlay
            if(!document.getElementById('ios-version-badge')){
                const versionDiv = document.createElement('div');
                versionDiv.id = 'ios-version-badge';
                versionDiv.textContent = 'iOS v\(version).\(build)';
                versionDiv.style.cssText = 'position:fixed;top:10px;right:10px;background:rgba(0,0,0,0.7);color:#fff;padding:5px 10px;border-radius:5px;font-size:12px;font-family:monospace;z-index:999999;';
                document.body.appendChild(versionDiv);
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

            // Click listener for Google OAuth links - CAPTURE PHASE
            if(!window._clickListenerAdded){
                document.addEventListener('click',function(e){
                    let el=e.target;
                    console.log('[iOS] Click detected on:', el.tagName, el.className);

                    // Traverse up to 10 parent elements to find the link
                    for(let i=0;i<10&&el;i++){
                        // Check both href attribute and onclick handlers
                        const href=el.getAttribute&&el.getAttribute('href');
                        const isGoogleAuth = href && (
                            href.includes('/auth/google/login') ||
                            href.includes('auth/google/login')
                        );

                        if(isGoogleAuth){
                            console.log('[iOS] ✅ Intercepted Google OAuth link:', href);

                            // CRITICAL: Stop all event propagation immediately
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();

                            // Extract return_url from href if present
                            let returnUrl = null;
                            try{
                                const url = new URL(href, window.location.origin);
                                returnUrl = url.searchParams.get('return_url');
                                console.log('[iOS] Return URL:', returnUrl);
                            }catch(err){
                                console.log('[iOS] Could not parse return_url:', err.message);
                            }

                            // Check plugin availability
                            if(!window.Capacitor?.Plugins?.NativeAuth){
                                console.error('[iOS] ❌ NativeAuth plugin not found!');
                                alert('Error: NativeAuth plugin not loaded. Plugins: ' + Object.keys(window.Capacitor?.Plugins||{}).join(', '));
                                return false;
                            }

                            console.log('[iOS] ✅ Calling native Google Sign-In...');

                            // Call native Google Sign-In
                            (async function(){
                                try{
                                    const result=await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();
                                    console.log('[iOS] Sign-in result:', JSON.stringify(result));

                                    if(result?.idToken){
                                        // Send ID token to backend
                                        const backendUrl = 'https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken);
                                        console.log('[iOS] Sending token to backend...');

                                        const response=await fetch(backendUrl,{
                                            method:'POST',
                                            headers:{'Content-Type':'application/json'}
                                        });

                                        if(response.ok){
                                            const data=await response.json();
                                            console.log('[iOS] ✅ Backend authentication successful');

                                            // Store authentication data
                                            localStorage.setItem('token',data.access_token||data.token);
                                            localStorage.setItem('user',JSON.stringify(data.user||{}));

                                            // Redirect to return_url or default
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
                                    console.error('[iOS] Sign-in error:', err.message);
                                    alert('Sign-in error: ' + err.message);
                                }
                            })();

                            return false;
                        }
                        el=el.parentElement;
                    }
                },true);
                window._clickListenerAdded = true;
                console.log('[iOS] ✅ Click listener added (enhanced for OAuth buttons)');
            }
        })();
        """

        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)

        NSLog("[NativeAuth] ✅ WKUserScript added - will run on every page load")
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
