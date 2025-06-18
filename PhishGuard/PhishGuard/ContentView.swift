//
//  ContentView.swift
//  PhishGuard
//
//  Created by Haroon Chaudhry on 3/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var disablePop = false
    @State private var urlToScan = ""
    @State private var isScanning = false
    @State private var scanResult: AnalysisStats?
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isURLFieldFocused: Bool
    
    private let scanner = URLScanner()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // URL Input
                    urlInputView
                    
                    // Scan Results
                    if let result = scanResult {
                        scanResultsView(result: result)
                    }
                    
                    Spacer()
                    
                    // Extension Setup Instructions
                    if !disablePop {
                        extensionSetupView
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("PhishGuard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Advanced URL Security Scanner")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }
    
    private var urlInputView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enter URL to Scan")
                .foregroundColor(.white)
                .font(.headline)
            
            HStack {
                TextField("example.com", text: $urlToScan)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .focused($isURLFieldFocused)
                    .placeholder(when: urlToScan.isEmpty) {
                        Text("https://example.com")
                            .foregroundColor(.gray)
                    }
                
                Button {
                    isURLFieldFocused = false
                    print("🔘 Scan button tapped - Button action triggered")
                    scanURL()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(isScanning ? Color.gray : Color.green)
                        .cornerRadius(8)
                }
                .disabled(urlToScan.isEmpty || isScanning)
                .overlay(
                    Group {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func scanResultsView(result: AnalysisStats) -> some View {
        VStack {
            ScrollView {
                VStack(spacing: 15) {
                    Text("Scan Results")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            StatBox(title: "Malicious", value: result.malicious, color: .red)
                            StatBox(title: "Suspicious", value: result.suspicious, color: .orange)
                            StatBox(title: "Harmless", value: result.harmless, color: .green)
                            StatBox(title: "Undetected", value: result.undetected, color: .gray)
                        }
                    }
                    
                    // Security Status
                    Text(result.malicious > 0 ? "⚠️ UNSAFE" : "✅ SAFE")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(result.malicious > 0 ? .red : .green)
                }
                .padding()
                .frame(width: 370)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                .cornerRadius(15)
                .padding(.horizontal)
              
                
            }
            .frame(height: 300) // Adjust height as needed
        }
        .padding()
    }
    
    private var extensionSetupView: some View {
        
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Safari Extension Setup")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("1. Open Settings > Safari > Extensions")
                    .foregroundColor(.gray)
                Text("2. Find 'PhishGuard'")
                    .foregroundColor(.gray)
                Text("3. Turn it on and allow access")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Button {
                disablePop = true
            } label: {
                Text("X")
                    .foregroundStyle(Color.red)
                    .padding(.trailing, 30)
            }
        }
      
    }
    
    private func scanURL() {
        print("🔘 Scan button tapped")
        guard !urlToScan.isEmpty else {
            print("❌ URL is empty")
            return
        }
        
        print("🔄 Starting scan for URL: \(urlToScan)")
        isScanning = true
        scanResult = nil // Clear previous results
        
        Task {
            do {
                print("📡 Initiating URL scan...")
                let scanResponse = try await scanner.scanURL(urlToScan)
                let analysisId = scanResponse.data.id
                print("⏳ Waiting for analysis to complete...")
                
                // Wait for a moment to allow the analysis to complete
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                print("📡 Getting analysis results...")
                let analysisResponse = try await scanner.getAnalysisResult(analysisId: analysisId)
                scanResult = analysisResponse.data.attributes.stats
                print("✅ Scan completed successfully")
            } catch let error as URLError {
                print("❌ Network error: \(error)")
                switch error.code {
                case .notConnectedToInternet:
                    errorMessage = "Please check your internet connection"
                case .timedOut:
                    errorMessage = "Request timed out. Please try again"
                case .badURL:
                    errorMessage = "Invalid URL format. Please enter a valid URL"
                case .badServerResponse:
                    errorMessage = "Server error. Please try again later"
                default:
                    errorMessage = "Network error: \(error.localizedDescription)"
                }
                showError = true
            } catch {
                print("❌ Unexpected error: \(error)")
                errorMessage = "Error: \(error.localizedDescription)"
                showError = true
            }
            
            isScanning = false
            print("🏁 Scan process completed")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: 70)
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(10)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ContentView()
}
