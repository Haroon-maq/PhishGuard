import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let scanner = URLScanner()
    
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo?[SFExtensionMessageKey] as! [String: Any]
        
        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", message)
        
        guard let url = message["url"] as? String else {
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["error": "No URL provided"]]
            context.completeRequest(returningItems: [response], completionHandler: nil)
            return
        }
        
        Task {
            do {
                let scanResponse = try await scanner.scanURL(url)
                let analysisId = scanResponse.data.id
                
                // Wait for a moment to allow the analysis to complete
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                let analysisResponse = try await scanner.getAnalysisResult(analysisId: analysisId)
                let stats = analysisResponse.data.attributes.stats
                
                let response = NSExtensionItem()
                response.userInfo = [SFExtensionMessageKey: [
                    "malicious": stats.malicious,
                    "suspicious": stats.suspicious,
                    "harmless": stats.harmless,
                    "undetected": stats.undetected,
                    "isSafe": stats.malicious == 0
                ]]
                
                context.completeRequest(returningItems: [response], completionHandler: nil)
            } catch {
                let response = NSExtensionItem()
                response.userInfo = [SFExtensionMessageKey: ["error": error.localizedDescription]]
                context.completeRequest(returningItems: [response], completionHandler: nil)
            }
        }
    }
} 