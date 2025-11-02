import Foundation
import Capacitor
import WebKit

/// Automatically adds os=apple parameter to all my-coach-finder.com URLs
/// Uses WKUserScript injection to handle ALL navigation types (links, JS redirects, SPAs, etc.)
@objc(OSParameterPlugin)
public class OSParameterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "OSParameterPlugin"
    public let jsName = "OSParameter"
    public let pluginMethods: [CAPPluginMethod] = []

    override public func load() {
        NSLog("[OSParameter] ✅ Plugin loaded - injecting JavaScript for os=apple parameter")

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

            // Inject JavaScript to handle ALL navigation types
            self?.injectOSParameterScript(into: webView)
        }
    }

    /// Injects JavaScript that adds os=apple to all navigation
    private func injectOSParameterScript(into webView: WKWebView) {
        let script = """
        (function() {
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
                    console.log('[OSParameter] ✅ Added os=apple:', url, '→', newUrl);
                    return newUrl;
                } catch (e) {
                    console.warn('[OSParameter] ⚠️ Could not parse URL:', url, e);
                    return url;
                }
            }

            // 1. Fix current URL on page load
            (function fixCurrentURL() {
                const currentUrl = window.location.href;
                if (currentUrl.includes('my-coach-finder.com') && !currentUrl.includes('os=apple')) {
                    const newUrl = addOSParameter(currentUrl);
                    if (newUrl !== currentUrl) {
                        console.log('[OSParameter] 🔄 Fixing current URL');
                        window.history.replaceState(null, '', newUrl);
                    }
                }
            })();

            // 2. Intercept window.location.href assignments
            const originalLocationDescriptor = Object.getOwnPropertyDescriptor(window, 'location');
            let locationValue = window.location;

            Object.defineProperty(window, 'location', {
                get: function() {
                    return locationValue;
                },
                set: function(value) {
                    const url = typeof value === 'string' ? value : value.href;
                    const modifiedUrl = addOSParameter(url);
                    locationValue = modifiedUrl;
                    originalLocationDescriptor.set.call(window, modifiedUrl);
                }
            });

            // 3. Intercept history.pushState and history.replaceState (for SPAs)
            const originalPushState = window.history.pushState;
            window.history.pushState = function(state, title, url) {
                const modifiedUrl = addOSParameter(url);
                return originalPushState.call(window.history, state, title, modifiedUrl);
            };

            const originalReplaceState = window.history.replaceState;
            window.history.replaceState = function(state, title, url) {
                const modifiedUrl = addOSParameter(url);
                return originalReplaceState.call(window.history, state, title, modifiedUrl);
            };

            // 4. Intercept link clicks
            document.addEventListener('click', function(e) {
                let target = e.target;

                // Find the <a> tag (might be nested)
                while (target && target.tagName !== 'A') {
                    target = target.parentElement;
                }

                if (target && target.tagName === 'A' && target.href) {
                    const modifiedHref = addOSParameter(target.href);
                    if (modifiedHref !== target.href) {
                        target.href = modifiedHref;
                    }
                }
            }, true);

            // 5. Intercept window.open
            const originalOpen = window.open;
            window.open = function(url, ...args) {
                const modifiedUrl = addOSParameter(url);
                return originalOpen.call(window, modifiedUrl, ...args);
            };

            // 6. Observe DOM changes to fix dynamically added links
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'A' && node.href) {
                            const modifiedHref = addOSParameter(node.href);
                            if (modifiedHref !== node.href) {
                                node.href = modifiedHref;
                            }
                        }
                    });
                });
            });

            observer.observe(document.documentElement, {
                childList: true,
                subtree: true
            });

            console.log('[OSParameter] ✅ All navigation interception active');
        })();
        """

        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        webView.configuration.userContentController.addUserScript(userScript)
        NSLog("[OSParameter] ✅ WKUserScript injected - all navigation will include os=apple")
    }
}
