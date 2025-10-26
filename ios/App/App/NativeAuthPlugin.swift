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

        // Inject JavaScript bridge when plugin loads
        // Use a small delay to ensure Capacitor is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSLog("[NativeAuth] Injecting JavaScript bridge now...")
            self.injectJavaScriptBridge()
        }
    }

    // MARK: - Capacitor Navigation Override

    @objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
        guard let url = navigationAction.request.url else {
            NSLog("[NativeAuth] shouldOverrideLoad: No URL in navigation action")
            return nil
        }

        let urlString = url.absoluteString
        NSLog("[NativeAuth] shouldOverrideLoad called for URL: %@", urlString)

        // Block Google OAuth login path - JavaScript will handle with native sign-in
        if urlString.contains("/auth/google/login") {
            NSLog("[NativeAuth] ❌ Blocking OAuth login path (native sign-in will handle): %@", urlString)
            // Return true to prevent loading
            return true
        }

        // Block Google OAuth redirects - our native sign-in will handle this
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

    private func injectJavaScriptBridge() {
        // Get app version from bundle
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let script = """
        (function(){
            if(!window.Capacitor)return;
            console.log('[Native Bridge iOS] Injecting auth bridge');
            console.log('[iOS App Version] \(version) (Build \(build))');

            // Add visible version overlay
            const versionDiv = document.createElement('div');
            versionDiv.id = 'ios-version-badge';
            versionDiv.textContent = 'iOS v\(version).\(build)';
            versionDiv.style.cssText = 'position:fixed;top:10px;right:10px;background:rgba(0,0,0,0.7);color:#fff;padding:5px 10px;border-radius:5px;font-size:12px;font-family:monospace;z-index:999999;';
            document.body.appendChild(versionDiv);

            // Override window.open to keep navigation in WebView
            const originalOpen = window.open;
            window.open = function(url, target, features) {
                // If opening app domain URLs, force them to stay in WebView
                if(url && url.includes('my-coach-finder.com')){
                    console.log('[iOS] Intercepting window.open, keeping in WebView:', url);
                    return originalOpen.call(this, url, '_self', features);
                }
                return originalOpen.call(this, url, target, features);
            };

            // Click listener for Google OAuth links - CAPTURE PHASE (runs first)
            document.addEventListener('click',function(e){
                let el=e.target;
                console.log('[iOS] Click detected on:', el.tagName, el.className);

                // Traverse up to 5 levels to find parent with href
                for(let i=0;i<5&&el;i++){
                    const href=el.getAttribute('href');
                    if(href){
                        console.log('[iOS] Found href:', href);

                        if(href.includes('/auth/google/login')){
                            console.log('[iOS] ✅ Intercepted Google OAuth link - preventing default');
                            e.preventDefault();
                            e.stopPropagation();
                            e.stopImmediatePropagation();

                            // Call native Google Sign-In
                            (async function(){
                                try{
                                    console.log('[iOS] Calling native Google Sign-In...');
                                    const result=await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();
                                    console.log('[iOS] Sign-in result:', result);

                                    if(result?.idToken){
                                        console.log('[iOS] Got ID token, sending to backend...');
                                        const response=await fetch('https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken),{
                                            method:'POST',
                                            headers:{'Content-Type':'application/json'}
                                        });

                                        if(response.ok){
                                            const data=await response.json();
                                            console.log('[iOS] Backend response:', data);
                                            const token=data.access_token||data.token;
                                            const user=JSON.stringify(data.user||{});
                                            localStorage.setItem('token',token);
                                            localStorage.setItem('user',user);
                                            console.log('[iOS] Token saved, redirecting to home...');
                                            window.location.href='https://app.my-coach-finder.com/';
                                        }else{
                                            console.error('[iOS] Backend error:', response.status);
                                        }
                                    }
                                }catch(err){
                                    console.error('[iOS] Auth error:',err);
                                }
                            })();

                            return false;
                        }
                    }
                    el=el.parentElement;
                }
            },true);
        })();
        """

        self.bridge?.webView?.evaluateJavaScript(script, completionHandler: nil)
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
