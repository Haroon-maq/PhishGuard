import Foundation

struct URLScanResponse: Codable {
    let data: URLScanData
}

struct URLScanData: Codable {
    let type: String
    let id: String
    let links: URLScanLinks
}

struct URLScanLinks: Codable {
    let selfLink: String
    
    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
    }
}

struct AnalysisResponse: Codable {
    let data: AnalysisData
}

struct AnalysisData: Codable {
    let attributes: AnalysisAttributes
}

struct AnalysisAttributes: Codable {
    let stats: AnalysisStats
}

struct AnalysisStats: Codable {
    let malicious: Int
    let suspicious: Int
    let harmless: Int
    let undetected: Int
}

class URLScanner {
    private let apiKey = "YOUR_API_KEY"
    
    func scanURL(_ url: String) async throws -> URLScanResponse {
        print("🔍 Scanning URL: \(url)")
        
        // Ensure URL is properly formatted
        var formattedURL = url
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            formattedURL = "https://" + url
        }
        print("📝 Formatted URL: \(formattedURL)")
        
        // URL encode the parameters
        let parameters = ["url": formattedURL]
        let encodedParameters = parameters.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")
        
        let postData = Data(encodedParameters.utf8)
        
        guard let requestURL = URL(string: "https://www.virustotal.com/api/v3/urls") else {
            print("❌ Invalid request URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-apikey": apiKey,
            "content-type": "application/x-www-form-urlencoded"
        ]
        request.httpBody = postData
        
        print("📤 Sending request to VirusTotal...")
        print("Request URL: \(requestURL)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: postData, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw URLError(.badServerResponse)
        }
        
        print("📥 Received response with status code: \(httpResponse.statusCode)")
        
        // Print the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server returned error status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(URLScanResponse.self, from: data)
            print("✅ Successfully decoded scan response")
            print("Analysis ID: \(decodedResponse.data.id)")
            return decodedResponse
        } catch {
            print("❌ Failed to decode response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Failed Response: \(responseString)")
            }
            throw error
        }
    }
    
    func getAnalysisResult(analysisId: String) async throws -> AnalysisResponse {
        print("🔍 Getting analysis result for ID: \(analysisId)")
        
        guard let url = URL(string: "https://www.virustotal.com/api/v3/analyses/\(analysisId)") else {
            print("❌ Invalid analysis URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "x-apikey": apiKey
        ]
        
        print("📤 Sending analysis request...")
        print("Request URL: \(url)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw URLError(.badServerResponse)
        }
        
        print("📥 Received analysis response with status code: \(httpResponse.statusCode)")
        
        // Print the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Analysis Response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server returned error status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            print("✅ Successfully decoded analysis response")
            print("Stats: Malicious: \(decodedResponse.data.attributes.stats.malicious), Suspicious: \(decodedResponse.data.attributes.stats.suspicious)")
            return decodedResponse
        } catch {
            print("❌ Failed to decode analysis response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Failed Response: \(responseString)")
            }
            throw error
        }
    }
} 
