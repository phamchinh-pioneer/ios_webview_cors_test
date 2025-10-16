import Foundation
import WebKit

class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView,
                 start urlSchemeTask: WKURLSchemeTask) {
        
        // Map your custom URL to a real local file
        if let url = urlSchemeTask.request.url,
           url.host == "local" {
            
            let fileName = url.pathComponents.last ?? "index.html"
            
            if let filePath = Bundle.main.path(forResource: fileName, ofType: nil),
               let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                
                let mimeType = fileName.hasSuffix(".html") ? "text/html" :
                               fileName.hasSuffix(".js")   ? "application/javascript" :
                               fileName.hasSuffix(".css")  ? "text/css" :
                               "text/plain"
                
                let response = URLResponse(
                    url: url,
                    mimeType: mimeType,
                    expectedContentLength: data.count,
                    textEncodingName: "utf-8"
                )
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
                return
            }
        }
        
        // Fallback if not found
        let error = NSError(domain: "LocalSchemeHandler",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "File not found"])
        urlSchemeTask.didFailWithError(error)
    }
    
    func webView(_ webView: WKWebView,
                 stop urlSchemeTask: WKURLSchemeTask) {
        // No-op
    }
}
