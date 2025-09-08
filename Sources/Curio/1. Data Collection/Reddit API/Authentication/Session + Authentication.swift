// Copyright (c) 2023 Jim Wallace
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Session {
    var isAuthenticated: Bool {
        return access_token != nil
    }
    
    // Authenticate with the Reddit API
    // After this call, we should have an authentication token, and be able to make requests
    func authenticate() async throws -> Bool {
        
        guard let client_id = client_id, let client_secret = client_secret else {
            debugPrint("Must initialize client_Id and client_secret to authenticate.")
            return false
        }
        
        // Create a data request
        var request = URLRequest(url: URL(string: baseAPIURL + "v1/access_token")!)
        request.httpMethod = "POST"
        
        // Set headers
        request.allHTTPHeaderFields = httpHeaders
        let credentials = "\(client_id):\(client_secret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        // Set body
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        #if canImport(FoundationNetworking)
        let data: Data = try await withCheckedThrowingContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data else {
                        
                        if let response = response {
                            print("Response: \(response)")
                        }
                        
                        guard let error = error else {
                            let fakeError = SessionError(message: "Authentication error. Response: \(response?.description ?? "None")")
                            continuation.resume(throwing: fakeError)
                            return
                        }
                     
                        continuation.resume(throwing: error)
                        return
                        
                    }
                    continuation.resume(returning: data)
                }.resume()
            }
        #else
        let (data, _) = try await session.data(for: request)
        #endif
        
        do {
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            //debugPrint(authResponse)
            
            // Store the information we need
            access_token = authResponse.access_token
            self.authResponse = authResponse
            
            // Add a header for our bearer token
            httpHeaders["Authorization"] = "bearer " + authResponse.access_token
            
            return true
            
        } catch {
            
            // Make sure we know that we're no longer authorized
            access_token = nil
            self.authResponse = nil
            if httpHeaders.keys.contains("Authorization") {
                httpHeaders.removeValue(forKey: "Authorization")
            }
            
            // Handle decoding error
            //debugPrint(String(data: data, encoding: .utf8)!)
            print("Error decoding JSON: \(error)")
            return false
        }
    }
}
