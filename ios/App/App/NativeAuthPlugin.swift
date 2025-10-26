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
        // Inject JavaScript bridge when plugin loads
        // Use a small delay to ensure Capacitor is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.injectJavaScriptBridge()
        }
    }

    // MARK: - Capacitor Navigation Override

    @objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
        guard let url = navigationAction.request.url else {
            return nil
        }

        let urlString = url.absoluteString

        // Keep all app domain URLs in WebView (don't open in Safari)
        if urlString.contains("app.my-coach-finder.com") {
            // Return false to allow loading in WebView
            return false
        }

        // Block Google OAuth redirects - our native sign-in will handle this
        if urlString.contains("accounts.google.com") {
            // Return true to prevent loading (JavaScript will handle it)
            return true
        }

        // For all other URLs, use Capacitor's default behavior
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

            // Click listener for Google OAuth links
            document.addEventListener('click',async function(e){
                let el=e.target;
                for(let i=0;i<5&&el;i++){
                    const href=String(el.getAttribute('href')||'').toLowerCase();
                    if(href.includes('/auth/google/login')){
                        console.log('[iOS] Intercepted Google OAuth click');
                        e.preventDefault();
                        e.stopPropagation();

                        try{
                            const result=await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();
                            if(result?.idToken){
                                const response=await fetch('https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken),{
                                    method:'POST',
                                    headers:{'Content-Type':'application/json'}
                                });
                                if(response.ok){
                                    const data=await response.json();
                                    const token=data.access_token||data.token;
                                    const user=JSON.stringify(data.user||{});
                                    localStorage.setItem('token',token);
                                    localStorage.setItem('user',user);
                                    window.location.href='https://app.my-coach-finder.com/';
                                }
                            }
                        }catch(err){
                            console.error('[iOS] Auth error:',err);
                        }
                        return false;
                    }
                    el=el.parentElement;
                    if(!el)break;
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
