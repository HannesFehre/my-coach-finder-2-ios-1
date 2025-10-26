import Foundation
import Capacitor
import GoogleSignIn

@objc(NativeAuthPlugin)
public class NativeAuthPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeAuthPlugin"
    public let jsName = "NativeAuth"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "signInWithGoogle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "signOut", returnType: CAPPluginReturnPromise)
    ]

    private let googleClientId = "353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com"

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
