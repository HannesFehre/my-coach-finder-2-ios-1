import UIKit
import Capacitor
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Listen for page load events to inject JavaScript bridge
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(capacitorDidLoad),
            name: Notification.Name.capacitorDidLoad,
            object: nil
        )

        return true
    }

    @objc func capacitorDidLoad(_ notification: Notification) {
        // Get the bridge from the notification
        guard let bridge = notification.object as? CAPBridgeProtocol else { return }

        // Inject native auth JavaScript bridge
        injectNativeAuthBridge(bridge: bridge)
    }

    func injectNativeAuthBridge(bridge: CAPBridgeProtocol) {
        let script = """
        (function(){
            if(!window.Capacitor)return;
            console.log('[Native Bridge iOS] Injecting native auth');

            // Session Manager
            window.SessionManager={
                save:async function(token,user){
                    localStorage.setItem('token',token);
                    localStorage.setItem('user',user);
                    if(window.Capacitor.Plugins?.Preferences){
                        const Prefs=window.Capacitor.Plugins.Preferences;
                        await Prefs.set({key:'auth_token',value:token});
                        await Prefs.set({key:'auth_user',value:user});
                    }
                },
                clear:async function(){
                    localStorage.removeItem('token');
                    localStorage.removeItem('user');
                    if(window.Capacitor.Plugins?.Preferences){
                        const Prefs=window.Capacitor.Plugins.Preferences;
                        await Prefs.remove({key:'auth_token'});
                        await Prefs.remove({key:'auth_user'});
                    }
                }
            };

            // Click listener for Google Sign-In
            document.addEventListener('click',async function(e){
                let el=e.target;
                for(let i=0;i<5&&el;i++){
                    const href=String(el.getAttribute('href')||'').toLowerCase();
                    if(href.includes('/auth/google/login')){
                        console.log('[Native Bridge iOS] Intercepted Google OAuth');
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
                                    await window.SessionManager.save(token,user);
                                    window.location.href='https://app.my-coach-finder.com/';
                                }
                            }
                        }catch(err){
                            console.error('[Native Bridge iOS] Error:',err);
                        }
                        return false;
                    }
                    el=el.parentElement;
                    if(!el)break;
                }
            },true);
        })();
        """

        bridge.webView?.evaluateJavaScript(script, completionHandler: nil)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Called when the app was launched with a url. Feel free to add additional processing here,
        // but if you want the App API to support tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when the app was launched with an activity, including Universal Links.
        // Feel free to add additional processing here, but if you want the App API to support
        // tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}
