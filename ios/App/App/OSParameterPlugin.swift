import Foundation
import Capacitor
import WebKit

/// Automatically adds os=apple parameter to all my-coach-finder.com URLs
/// Uses direct JavaScript injection on every page load
@objc(OSParameterPlugin)
public class OSParameterPlugin: CAPPlugin, CAPBridgedPlugin, WKNavigationDelegate {
    public let identifier = "OSParameterPlugin"
    public let jsName = "OSParameter"
    public let pluginMethods: [CAPPluginMethod] = []

    private weak var originalNavigationDelegate: WKNavigationDelegate?

    override public func load() {
        NSLog("[OSParameter] ✅ Plugin loaded - will inject JavaScript on every page load")

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let webView = self.bridge?.webView else { return }

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

            // Store original navigation delegate and set ourselves
            self.originalNavigationDelegate = webView.navigationDelegate
            webView.navigationDelegate = self

            // Inject immediately for current page
            self.injectOSParameterScript(into: webView)
        }
    }

    /// WKNavigationDelegate method - called when page finishes loading
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("[OSParameter] 📄 Page loaded - injecting JavaScript")
        injectOSParameterScript(into: webView)

        // Forward to original delegate
        originalNavigationDelegate?.webView?(webView, didFinish: navigation)
    }

    /// Injects JavaScript directly into the page
    private func injectOSParameterScript(into webView: WKWebView) {
        let script = """
        (function() {
            // Prevent multiple injections
            if (window.__OSParameterInjected) {
                console.log('[OSParameter] Already injected, skipping');
                return;
            }
            window.__OSParameterInjected = true;

            console.log('[OSParameter] 🚀 JavaScript injection active');

            // Helper function to add os=apple parameter to URL
            function addOSParameter(url) {
                if (!url) return url;

                // Only modify my-coach-finder.com URLs
                if (!url.includes('my-coach-finder.com')) {
                    return url;
                }

                // Check if already has os=apple
                if (url.includes('os=apple')) {
                    return url;
                }

                try {
                    const urlObj = new URL(url, window.location.href);
                    urlObj.searchParams.set('os', 'apple');
                    const newUrl = urlObj.toString();

                    // Special logging for critical auth URLs
                    if (urlObj.pathname.includes('/auth/login') || urlObj.pathname.includes('/auth/register')) {
                        console.log('[OSParameter] ⚠️ CRITICAL AUTH URL - Added os=apple:', url, '→', newUrl);
                    } else {
                        console.log('[OSParameter] ✅ Added os=apple:', url, '→', newUrl);
                    }

                    return newUrl;
                } catch (e) {
                    console.warn('[OSParameter] ⚠️ Could not parse URL:', url, e);
                    return url;
                }
            }

            // 1. Fix current URL on page load (CRITICAL for auth pages)
            (function fixCurrentURL() {
                const currentUrl = window.location.href;
                if (currentUrl.includes('my-coach-finder.com') && !currentUrl.includes('os=apple')) {
                    const newUrl = addOSParameter(currentUrl);
                    if (newUrl !== currentUrl) {
                        const isAuthPage = currentUrl.includes('/auth/');
                        if (isAuthPage) {
                            console.log('[OSParameter] ⚠️ CRITICAL: Fixing auth page URL');
                        } else {
                            console.log('[OSParameter] 🔄 Fixing current URL');
                        }
                        window.history.replaceState(null, '', newUrl);
                    }
                }
            })();

            // 2. Intercept history.pushState and history.replaceState (for SPAs)
            const originalPushState = window.history.pushState;
            window.history.pushState = function(state, title, url) {
                const modifiedUrl = addOSParameter(url);
                console.log('[OSParameter] pushState:', url, '→', modifiedUrl);
                return originalPushState.call(window.history, state, title, modifiedUrl);
            };

            const originalReplaceState = window.history.replaceState;
            window.history.replaceState = function(state, title, url) {
                // Don't intercept our own replaceState calls
                if (arguments.callee.caller && arguments.callee.caller.toString().includes('fixCurrentURL')) {
                    return originalReplaceState.call(window.history, state, title, url);
                }
                const modifiedUrl = addOSParameter(url);
                console.log('[OSParameter] replaceState:', url, '→', modifiedUrl);
                return originalReplaceState.call(window.history, state, title, modifiedUrl);
            };

            // 3. Intercept link clicks
            document.addEventListener('click', function(e) {
                let target = e.target;

                // Find the <a> tag (might be nested)
                while (target && target.tagName !== 'A') {
                    target = target.parentElement;
                }

                if (target && target.tagName === 'A' && target.href) {
                    const modifiedHref = addOSParameter(target.href);
                    if (modifiedHref !== target.href) {
                        console.log('[OSParameter] Link click:', target.href, '→', modifiedHref);
                        target.href = modifiedHref;
                    }
                }
            }, true);

            // 4. Intercept window.location assignments
            let locationSetter = Object.getOwnPropertyDescriptor(window.location.constructor.prototype, 'href').set;
            Object.defineProperty(window.location, 'href', {
                set: function(url) {
                    const modifiedUrl = addOSParameter(url);
                    console.log('[OSParameter] location.href:', url, '→', modifiedUrl);
                    locationSetter.call(this, modifiedUrl);
                }
            });

            console.log('[OSParameter] ✅ All navigation interception active');
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                NSLog("[OSParameter] ❌ JavaScript injection failed: %@", error.localizedDescription)
            } else {
                NSLog("[OSParameter] ✅ JavaScript injected successfully")
            }
        }
    }

    // Forward other WKNavigationDelegate methods to original delegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // CRITICAL: Intercept auth URLs at native level to guarantee os=apple parameter
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            let path = url.path

            // Check if this is an auth URL
            let isAuthURL = path.contains("/auth/login") || path.contains("/auth/register")
            let isMCFDomain = url.host?.hasSuffix("my-coach-finder.com") ?? false
            let hasOSParam = urlString.contains("os=apple")

            if isAuthURL && isMCFDomain && !hasOSParam {
                // CRITICAL: Auth URL without os=apple - add it now!
                NSLog("[OSParameter] ⚠️ CRITICAL: Intercepting auth URL without os=apple: %@", urlString)

                if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                    var queryItems = components.queryItems ?? []
                    queryItems.append(URLQueryItem(name: "os", value: "apple"))
                    components.queryItems = queryItems

                    if let modifiedURL = components.url {
                        NSLog("[OSParameter] ✅ CRITICAL: Modified auth URL: %@ → %@", urlString, modifiedURL.absoluteString)

                        // Cancel this navigation and load the modified URL
                        decisionHandler(.cancel)
                        webView.load(URLRequest(url: modifiedURL))
                        return
                    }
                }
            }
        }

        // Forward to original delegate
        if let original = originalNavigationDelegate {
            original.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
}
