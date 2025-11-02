import Foundation
import Capacitor
import WebKit

/// Automatically adds os=apple parameter to all my-coach-finder.com URLs
/// Uses Capacitor's shouldOverrideLoad hook for reliable native-level interception
@objc(OSParameterPlugin)
public class OSParameterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "OSParameterPlugin"
    public let jsName = "OSParameter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "addOSParameter", returnType: CAPPluginReturnPromise)
    ]

    override public func load() {
        NSLog("[OSParameter] ✅ Plugin loaded - will intercept ALL navigation to add os=apple")
        NSLog("[OSParameter] 🎯 Critical URLs protected:")
        NSLog("[OSParameter]    • /auth/login?os=apple")
        NSLog("[OSParameter]    • /auth/register?os=apple")

        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.bridge?.webView else { return }

            // Set custom User-Agent as backup identification method
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

            webView.evaluateJavaScript("navigator.userAgent") { result, error in
                if let userAgent = result as? String {
                    let customUA = "\(userAgent) MyCoachFinder-iOS/\(version).\(build)"
                    webView.customUserAgent = customUA
                    NSLog("[OSParameter] ✅ Custom User-Agent set: %@", customUA)
                }
            }

            NSLog("[OSParameter] ✅ Navigation interception active - auth URLs will have os=apple")
        }
    }

    /// Capacitor's official navigation interception hook
    /// Called BEFORE every navigation - this is where we add os=apple
    @objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
        NSLog("[OSParameter] 🔍 shouldOverrideLoad CALLED!")

        guard let url = navigationAction.request.url else {
            NSLog("[OSParameter] ⚠️ No URL in navigation action")
            return nil // No URL, allow navigation
        }

        let urlString = url.absoluteString
        let host = url.host ?? ""
        let path = url.path

        NSLog("[OSParameter] 🔍 Checking URL: %@", urlString)
        NSLog("[OSParameter] 🔍 Host: %@", host)

        // Only modify my-coach-finder.com domains
        guard host.hasSuffix("my-coach-finder.com") else {
            NSLog("[OSParameter] ⏭️ Skipping external domain: %@", host)
            return nil // External domain, allow navigation
        }

        // Check if os=apple already exists
        if urlString.contains("os=apple") {
            NSLog("[OSParameter] ✅ URL already has os=apple: %@", path)
            return nil // Already has parameter, allow navigation
        }

        NSLog("[OSParameter] ⚠️ URL MISSING os=apple: %@", urlString)

        // Add os=apple parameter
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            NSLog("[OSParameter] ⚠️ Could not parse URL: %@", urlString)
            return nil // Can't parse, allow original navigation
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "os", value: "apple"))
        components.queryItems = queryItems

        guard let modifiedURL = components.url else {
            NSLog("[OSParameter] ⚠️ Could not construct modified URL")
            return nil
        }

        // Check if this is a critical auth URL
        let isAuthURL = path.contains("/auth/login") || path.contains("/auth/register")

        if isAuthURL {
            NSLog("[OSParameter] ⚠️ CRITICAL AUTH URL - Adding os=apple: %@ → %@",
                  urlString, modifiedURL.absoluteString)
        } else {
            NSLog("[OSParameter] 🔄 Adding os=apple: %@ → %@",
                  urlString, modifiedURL.absoluteString)
        }

        // Load the modified URL
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.bridge?.webView else {
                NSLog("[OSParameter] ❌ WebView not available")
                return
            }

            let modifiedRequest = URLRequest(url: modifiedURL)
            webView.load(modifiedRequest)
        }

        // Return true to cancel original navigation (we're loading modified URL instead)
        return true
    }

    /// JavaScript-callable method to manually add os=apple parameter
    @objc func addOSParameter(_ call: CAPPluginCall) {
        NSLog("[OSParameter] 📞 addOSParameter called from JavaScript")

        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.bridge?.webView else {
                call.reject("WebView not available")
                return
            }

            webView.evaluateJavaScript("window.location.href") { result, error in
                guard let currentURL = result as? String else {
                    call.reject("Could not get current URL")
                    return
                }

                NSLog("[OSParameter] 📞 Current URL from JS: %@", currentURL)

                // Check if already has os=apple
                if currentURL.contains("os=apple") {
                    NSLog("[OSParameter] ✅ URL already has os=apple")
                    call.resolve(["success": true, "url": currentURL])
                    return
                }

                // Add os=apple
                guard let url = URL(string: currentURL),
                      var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    call.reject("Could not parse URL")
                    return
                }

                var queryItems = components.queryItems ?? []
                queryItems.append(URLQueryItem(name: "os", value: "apple"))
                components.queryItems = queryItems

                guard let modifiedURL = components.url else {
                    call.reject("Could not create modified URL")
                    return
                }

                NSLog("[OSParameter] ✅ Adding os=apple via JS call: %@ → %@", currentURL, modifiedURL.absoluteString)

                // Reload with modified URL
                webView.load(URLRequest(url: modifiedURL))

                call.resolve(["success": true, "url": modifiedURL.absoluteString])
            }
        }
    }
}

// CRITICAL: Register plugin with Capacitor - WITHOUT THIS IT DOESN'T WORK!
CAP_PLUGIN(OSParameterPlugin, "OSParameter",
    CAP_PLUGIN_METHOD(addOSParameter, CAPPluginReturnPromise);
)
