import Foundation
import WebKit
import SwiftUI

class WebViewCoordinator: NSObject, WKScriptMessageHandler {
    
    weak var webView: WKWebView?

    override init() {
        super.init()
    }

    // Receives messages from JS
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              type == "SEND_HTTP_REQUEST",
              let uuid = body["uuid"] as? String,
              let urlString = body["url"] as? String,
              let url = URL(string: urlString),
              let method = body["method"] as? String else { return }

        let bodyString = body["body"] as? String ?? ""
        let contentType = body["content_type"] as? String ?? "application/json"
        let accept = body["accept"] as? String ?? "application/json"
        let customHeaders = body["custom_headers"] as? [String: String] ?? [:]

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = bodyString.data(using: .utf8)
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(accept, forHTTPHeaderField: "Accept")
        
        // Add custom headers (like Authorization)
        for (key, value) in customHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add Origin header for CORS testing (simulating web browser behavior)
        request.addValue("file://", forHTTPHeaderField: "Origin")

        print("📡 Sending request to:", url)
        print("Method:", method)
        print("Headers:", request.allHTTPHeaderFields ?? [:])
        if !customHeaders.isEmpty {
            print("Custom Headers:", customHeaders)
        }
        if !bodyString.isEmpty {
            print("Body:", bodyString)
        }
        
        // Add User-Agent to help with CORS debugging
        request.addValue("WebViewTest/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        // Send request asynchronously
        URLSession.shared.dataTask(with: request) { data, response, error in
            var responseData: [String: Any] = [:]
            
            if let error = error {
                print("❌ Request error:", error)
                responseData["error"] = error.localizedDescription
                responseData["errorCode"] = (error as NSError).code
            }

            if let resp = response as? HTTPURLResponse {
                print("✅ Response status:", resp.statusCode)
                print("Response headers:", resp.allHeaderFields)
                
                responseData["statusCode"] = resp.statusCode
                responseData["headers"] = resp.allHeaderFields
                
                // Check for CORS-related headers
                if let corsOrigin = resp.allHeaderFields["Access-Control-Allow-Origin"] as? String {
                    print("🌐 CORS Origin:", corsOrigin)
                }
                if let corsMethods = resp.allHeaderFields["Access-Control-Allow-Methods"] as? String {
                    print("🌐 CORS Methods:", corsMethods)
                }
                if let corsHeaders = resp.allHeaderFields["Access-Control-Allow-Headers"] as? String {
                    print("🌐 CORS Headers:", corsHeaders)
                }
            }

            var base64Data = ""
            if let data = data {
                base64Data = data.base64EncodedString()
                responseData["data"] = base64Data
                
                // Try to parse as JSON for better debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Response body:", jsonString)
                }
            }

            // Encode the full response as JSON
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                let escapedJson = jsonString.replacingOccurrences(of: "\"", with: "\\\"")
                
                // Return response to JS
                let js = """
                window.jsCallbackBridge.resolvePromise("\(uuid)", "\(escapedJson)");
                """
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript(js, completionHandler: nil)
                }
            } catch {
                print("❌ Failed to serialize response:", error)
                let js = """
                window.jsCallbackBridge.rejectPromise("\(uuid)", "Failed to serialize response");
                """
                DispatchQueue.main.async {
                    self.webView?.evaluateJavaScript(js, completionHandler: nil)
                }
            }

        }.resume()
    }
}
