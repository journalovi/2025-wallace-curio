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


extension Session {
    
    /// Returns a ``Subreddit`` object for the provided subreddit.
    /// - Parameter subreddit: The subreddit to retrieve information for.
    /// - Returns: A ``Subreddit`` object.
    @inlinable
    func aboutSubreddit(_ subreddit: String) async throws -> Subreddit {
        let parameters: [String : String] = [String:String]()
        
        let data = try await _GET(endpoint: "r/\(subreddit)/about", parameters: parameters)
        
        do {
            let data = try JSONDecoder().decode(ListingDataItem.self, from: data)
            if data.kind == .subreddit {
                return data.data as! Subreddit
            }
            throw SessionError(message: "Unable to decode server response.")
        } catch {
            throw SessionError(message: "Unable to decode server response.")
        }
    }
    
    /// Returns a ``Listing`` for the provided search terms from the r/subreddit/search endpoint.
    @inlinable
    func searchSubreddit(
        _ subreddit: String,
        query: String,
        after: String? = nil,
        before: String? = nil,
        count: UInt? = nil,
        limit: UInt? = nil,
        searchQuery: UUID? = nil,
        show: String? = "all",
        sort: ListingSortOrder = .comments,
        expandSubreddits: Bool? = nil,
        time: ListingTime = .all,
        restrictSubreddit: Bool = true,
        type: Set<RedditContentType> = [.link]
    ) async throws -> Listing {
        
        guard query.count < 512 else {
            throw SessionError(message: "Query length must be less than 512 characters.")
        }
        
        var parameters: [String : String] = [String:String]()
        
        parameters["q"] = "\"\(query)\""
        parameters["sort"] = sort.rawValue
        parameters["t"] = time.rawValue
        parameters["restrict_sr"] = String(restrictSubreddit).lowercased()
        
        // TODO: We can expand this to include user, subreddit types... is that useful?
        guard !type.isEmpty else {
            throw SessionError(message: "Must specify at least one type.")
        }
        
        let typeList: String = type.map { $0.rawValue }.joined(separator: ", ")
            
        parameters["type"] = typeList
        
        if let after = after {
            parameters["after"] = after
        }
        
        if let before = before {
            parameters["before"] = before
        }
        
        if let limit = limit {
            parameters["limit"] = String(limit)
        }
        
        if let count = count {
            parameters["count"] = String(count)
        }
        
        if let sr_detail = expandSubreddits {
            parameters["sr_detail"] = String(sr_detail).lowercased()
        }
        
        let data = try await _GET(endpoint: "r/\(subreddit)/search", parameters: parameters)
        
        do {
            return try JSONDecoder().decode(Listing.self, from: data)
        } catch {
            throw SessionError(message: "Unable to decode server response.")
        }
    }
}
