// Copyright (c) 2024 Jim Wallace
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
    /// Perform a basic GET to the Reddit API given an endpoint and parameters
    /// - Parameters:
    ///   - endpoint: The endpoint to hit
    ///   - parameters: The parameters to pass
    /// - Returns: The data returned from the API
    /// - Throws: Any errors that occur
    @inlinable
    internal func _GET(endpoint: String, parameters: [String : String]) async throws -> Data {
        guard isAuthenticated else {
            throw SessionError(message: "Client not authenticated.")
        }
        
        var url = URLComponents(string: authorizedAPIURL + endpoint)
        
        // Load up our query items
        var queryItems = [URLQueryItem]()
        for (key, value) in parameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        url?.queryItems = queryItems
        
        guard let url = url?.url else {
            throw SessionError(message: "Could not form query URL")
        }
        
        // Create a data request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set headers
        request.allHTTPHeaderFields = httpHeaders
                
        #if canImport(FoundationNetworking)
        let (data,response) = await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: request) { data, response, _ in
                    guard let data = data, let response = response else {
                        fatalError()
                    }
                    continuation.resume(returning: (data,response))
                }.resume()
            }
        #else
        let (data, response) = try await URLSession.shared.data(for: request)
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SessionError(message: "Bad server response" + response.description)
        }
        
        // Monitor rate limits
        if httpResponse.allHeaderFields.keys.contains("x-ratelimit-used") {
            if let tmp = httpResponse.allHeaderFields["x-ratelimit-used"] as? String {
                rateLimitUsed = Int(tmp) ?? -1
            }
        }
        if httpResponse.allHeaderFields.keys.contains("x-ratelimit-remaining") {
            if let tmp = httpResponse.allHeaderFields["x-ratelimit-remaining"] as? String {
                rateLimitUsed = Int(tmp) ?? -1
            }
        }
        if httpResponse.allHeaderFields.keys.contains("x-ratelimit-reset") {
            if let tmp = httpResponse.allHeaderFields["x-ratelimit-reset"] as? String {
                rateLimitReset = Int(tmp) ?? -1
            }
        }
        
        return data
    }
}
