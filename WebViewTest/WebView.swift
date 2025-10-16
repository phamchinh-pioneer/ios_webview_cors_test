import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    var htmlFileName: String

    func makeCoordinator() -> WebViewCoordinator {
        return WebViewCoordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "native")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        // Enable debugging and better CORS handling
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.allowsInlineMediaPlayback = true
        
        // Create webview with enhanced configuration
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Store reference in coordinator
        context.coordinator.webView = webView
        
        // Enable debugging
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        if let path = Bundle.main.path(forResource: htmlFileName, ofType: "html") {
            let url = URL(fileURLWithPath: path)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
