import Foundation
import Capacitor
import WebKit

/// Automatically adds os=apple parameter to all my-coach-finder.com navigation requests
@objc(OSParameterPlugin)
public class OSParameterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "OSParameterPlugin"
    public let jsName = "OSParameter"
    public let pluginMethods: [CAPPluginMethod] = []

    override public func load() {
        NSLog("[OSParameter] ✅ Plugin loaded - will add os=apple to all navigation")
    }

    /// Intercepts navigation to add os=apple parameter
    @objc override public func shouldOverrideLoad(_ navigationAction: WKNavigationAction) -> NSNumber? {
        guard let url = navigationAction.request.url else {
            return nil // No URL, continue with default behavior
        }

        let urlString = url.absoluteString
        let host = url.host ?? ""

        // Only modify my-coach-finder.com domains (including subdomains)
        guard host.hasSuffix("my-coach-finder.com") else {
            return nil // Not our domain, continue with default behavior
        }

        // Check if os=apple parameter already exists
        if urlString.contains("os=apple") {
            NSLog("[OSParameter] ✅ URL already has os=apple: %@", urlString)
            return nil // Already has parameter, allow navigation
        }

        // Create URL components to safely add parameter
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            NSLog("[OSParameter] ⚠️ Could not parse URL components: %@", urlString)
            return nil // Can't parse, continue with default
        }

        // Add os=apple to query parameters
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "os", value: "apple"))
        urlComponents.queryItems = queryItems

        guard let modifiedURL = urlComponents.url else {
            NSLog("[OSParameter] ⚠️ Could not construct modified URL")
            return nil
        }

        NSLog("[OSParameter] 🔄 Modified URL: %@ → %@", urlString, modifiedURL.absoluteString)

        // Load the modified URL in the WebView
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.bridge?.webView else {
                NSLog("[OSParameter] ❌ WebView not available")
                return
            }

            let modifiedRequest = URLRequest(url: modifiedURL)
            webView.load(modifiedRequest)
        }

        // Return true to cancel the original navigation (we're loading the modified URL instead)
        return true
    }
}
