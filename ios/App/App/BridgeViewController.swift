import UIKit
import Capacitor
import WebKit

class BridgeViewController: CAPBridgeViewController, WKNavigationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure WebView to keep everything in-app (like Android)
        if let webView = self.bridge?.webView {
            webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            webView.navigationDelegate = self
        }

        // Inject native auth bridge after WebView loads
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(webViewDidFinishLoad),
            name: Notification.Name.capacitorDidLoad,
            object: nil
        )
    }

    // Keep all navigation in the WebView - don't open Safari automatically
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow all navigation to stay in the WebView
        // The JavaScript bridge will intercept Google OAuth clicks and call native sign-in
        decisionHandler(.allow)
    }

    @objc func webViewDidFinishLoad() {
        // Inject the native auth bridge JavaScript
        injectNativeAuthBridge()
        injectPushNotifications()
    }

    private func injectNativeAuthBridge() {
        let nativeAuthScript = """
        (function(){
            if(!window.Capacitor)return;
            console.log('[Native Bridge iOS] Injecting native auth and session manager');

            // Session Manager with fallback
            window.SessionManager={
                checkAndRestore:async function(){
                    try{
                        console.log('[Session] Checking for saved session...');
                        if(!window.Capacitor.Plugins||!window.Capacitor.Plugins.Preferences){
                            console.log('[Session] Preferences plugin not available, using localStorage only');
                            return false;
                        }
                        const Prefs=window.Capacitor.Plugins.Preferences;
                        const token=await Prefs.get({key:'auth_token'});
                        const user=await Prefs.get({key:'auth_user'});
                        if(token.value&&user.value){
                            console.log('[Session] Restoring saved session');
                            localStorage.setItem('token',token.value);
                            localStorage.setItem('user',user.value);
                            return true;
                        }
                    }catch(e){console.error('[Session] Error restoring:',e);}
                    return false;
                },
                save:async function(token,user){
                    try{
                        console.log('[Session] Saving session to localStorage');
                        localStorage.setItem('token',token);
                        localStorage.setItem('user',user);
                        if(window.Capacitor.Plugins&&window.Capacitor.Plugins.Preferences){
                            console.log('[Session] Also saving to persistent storage');
                            const Prefs=window.Capacitor.Plugins.Preferences;
                            await Prefs.set({key:'auth_token',value:token});
                            await Prefs.set({key:'auth_user',value:user});
                            console.log('[Session] Saved successfully');
                        }else{
                            console.log('[Session] Preferences not available, localStorage only');
                        }
                    }catch(e){console.error('[Session] Error saving:',e);}
                },
                clear:async function(){
                    try{
                        console.log('[Session] Clearing session');
                        localStorage.removeItem('token');
                        localStorage.removeItem('user');
                        if(window.Capacitor.Plugins&&window.Capacitor.Plugins.Preferences){
                            const Prefs=window.Capacitor.Plugins.Preferences;
                            await Prefs.remove({key:'auth_token'});
                            await Prefs.remove({key:'auth_user'});
                        }
                    }catch(e){console.error('[Session] Error clearing:',e);}
                }
            };

            // Auto-restore session on login pages OR detect logout
            setTimeout(async function(){
                const currentUrl=window.location.href;
                const isLoginPage=currentUrl.includes('/auth/login')||currentUrl.includes('/auth/signup');
                const hasToken=localStorage.getItem('token');

                if(isLoginPage){
                    if(hasToken){
                        console.log('[Session] On login page with token, attempting auto-login');
                        const restored=await window.SessionManager.checkAndRestore();
                        if(restored){
                            console.log('[Session] Auto-login successful, redirecting');
                            window.location.href='https://app.my-coach-finder.com/';
                        }
                    }else{
                        console.log('[Session] On login page without token, clearing any persisted session');
                        await window.SessionManager.clear();
                    }
                }else{
                    const token=localStorage.getItem('token');
                    const user=localStorage.getItem('user');
                    if(token&&user){
                        await window.SessionManager.save(token,user);
                    }
                }
            },500);

            // Click event listener for Google Sign-In ONLY
            document.addEventListener('click',async function(e){
                let el=e.target;
                for(let i=0;i<5&&el;i++){
                    if(!el.tagName)break;
                    const tag=el.tagName.toLowerCase();
                    if(tag!=='button'&&tag!=='a'&&tag!=='div'&&tag!=='span'){el=el.parentElement;continue;}
                    const txt=(el.textContent||'').toLowerCase().trim();
                    const cls=String(el.className||'').toLowerCase();
                    const id=String(el.id||'').toLowerCase();
                    const dataProvider=String(el.getAttribute('data-provider')||'').toLowerCase();
                    const href=String(el.getAttribute('href')||'').toLowerCase();

                    // Check for Google OAuth redirect link
                    const isGoogleAuthLink=(tag==='a'&&href.includes('/auth/google/login'));

                    if(isGoogleAuthLink){
                        console.log('[Native Bridge iOS] Intercepted Google OAuth link:',href);
                        e.preventDefault();
                        e.stopPropagation();

                        // Extract return_url from href
                        let returnUrl='https://app.my-coach-finder.com/';
                        const fullHref=el.getAttribute('href')||'';
                        const returnMatch=fullHref.match(/return_url=([^&]+)/);
                        if(returnMatch){
                            returnUrl=decodeURIComponent(returnMatch[1]);
                            if(!returnUrl.startsWith('http')){
                                returnUrl='https://app.my-coach-finder.com'+returnUrl;
                            }
                            console.log('[Native Bridge iOS] Will redirect to:',returnUrl);
                        }

                        // Call native Google Sign-In
                        console.log('[Native Bridge iOS] Triggering native Google Sign-In...');
                        try{
                            const result=await window.Capacitor.Plugins.NativeAuth.signInWithGoogle();
                            console.log('[Native Bridge iOS] Native auth result:',result);

                            if(result&&result.idToken){
                                console.log('[Native Bridge iOS] Got ID token, sending to backend...');
                                const response=await fetch('https://app.my-coach-finder.com/auth/google/native?id_token='+encodeURIComponent(result.idToken),{
                                    method:'POST',
                                    headers:{'Content-Type':'application/json'}
                                });
                                console.log('[Native Bridge iOS] Backend response status:',response.status);

                                if(response.ok){
                                    const data=await response.json();
                                    console.log('[Native Bridge iOS] Login successful, token:',data.access_token?'present':'missing');
                                    const token=data.access_token||data.token;
                                    const user=JSON.stringify(data.user||{});
                                    localStorage.setItem('token',token);
                                    localStorage.setItem('user',user);
                                    await window.SessionManager.save(token,user);
                                    console.log('[Native Bridge iOS] Redirecting to:',returnUrl);
                                    window.location.href=returnUrl;
                                }else{
                                    const errorText=await response.text();
                                    console.error('[Native Bridge iOS] Backend returned error:',response.status,errorText);
                                    alert('Login failed: '+errorText);
                                }
                            }else{
                                console.log('[Native Bridge iOS] No ID token received, user may have cancelled');
                            }
                        }catch(err){
                            console.error('[Native Bridge iOS] Error during native sign-in:',err);
                            alert('Login error: '+err.message);
                        }

                        return false;
                    }

                    el=el.parentElement;
                }
            },true);

            console.log('[Native Bridge iOS] Native auth bridge active');
        })();
        """

        self.bridge?.webView?.evaluateJavaScript(nativeAuthScript, completionHandler: nil)
    }

    private func injectPushNotifications() {
        let pushNotificationScript = """
        (function(){
            if(!window.Capacitor||!window.Capacitor.Plugins.PushNotifications)return;
            console.log('[Push iOS] Initializing push notifications');
            const PushNotifications=window.Capacitor.Plugins.PushNotifications;
            PushNotifications.checkPermissions().then(status=>{
                console.log('[Push iOS] Permission status:',status.receive);
                if(status.receive==='granted'){
                    console.log('[Push iOS] Permission already granted, registering...');
                    PushNotifications.register();
                    return;
                }
                console.log('[Push iOS] Requesting permissions...');
                PushNotifications.requestPermissions().then(result=>{
                    console.log('[Push iOS] Permission result:',result.receive);
                    if(result.receive==='granted'){
                        console.log('[Push iOS] Permission granted, registering...');
                        PushNotifications.register();
                    }
                });
            });
            PushNotifications.addListener('registration',token=>{
                console.log('[Push iOS] Token registered:',token.value);
                localStorage.setItem('fcm_token',token.value);
                localStorage.setItem('device_platform','ios');
                console.log('[Push iOS] Token saved to localStorage');
            });
            PushNotifications.addListener('registrationError',error=>{
                console.error('[Push iOS] Registration error:',error);
            });
        })();
        """

        self.bridge?.webView?.evaluateJavaScript(pushNotificationScript, completionHandler: nil)
    }
}
