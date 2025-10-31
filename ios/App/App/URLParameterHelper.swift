import Foundation

/// Helper class to add os=apple parameter to URLs
@objc public class URLParameterHelper: NSObject {

    /// Adds os=apple parameter to a URL string
    @objc public static func addOSParameter(to urlString: String) -> String {
        // Check if already has os=apple
        if urlString.contains("os=apple") {
            return urlString
        }

        guard let url = URL(string: urlString),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return urlString
        }

        // Only modify my-coach-finder.com domains
        guard let host = components.host, host.hasSuffix("my-coach-finder.com") else {
            return urlString
        }

        // Add os=apple parameter
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "os", value: "apple"))
        components.queryItems = queryItems

        return components.url?.absoluteString ?? urlString
    }
}
