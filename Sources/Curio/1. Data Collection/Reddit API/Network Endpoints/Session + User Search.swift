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

extension Session {
    
    /// Returns a comment ``Listing`` corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserOverview(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "overview",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserSubmitted(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "submitted",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/ endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserComments(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "comments",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserUpvoted(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "upvoted",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserDownvoted(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "downvoted",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserHidden(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "hidden",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    ///  - Returns: A ``Listing`` of comments
    func searchUserSaved(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "saved",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment listing corresponding to  /user/username/comments/overview endpoint
    /// - Returns: A ``Listing`` of comments
    func searchUserGilded(
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
        return try await _searchUserEndpoint(
            "gilded",
            userName: userName,
            context: context,
            sort: sort,
            time: time,
            type: type,
            after: after,
            before: before,
            count: count,
            limit: limit,
            expandSubreddits: expandSubreddits
        )
    }
    
    /// Returns a comment tree corresponding to a search of a given /user/username/ endpoint
    @inlinable
    internal func _searchUserEndpoint(
        _ endPoint: String,
        userName: String,
        context: UInt = 10,
        // SHOW?
        sort: ListingSortOrder = .new,
        time: ListingTime = .all,
        type: RedditContentType = .link,
        after: String? = nil,
        before: String? = nil,
        count: UInt = 0,
        limit: Int? = nil,
        expandSubreddits: Bool = false
    ) async throws -> Listing {
                      
        var parameters: [String : String] = [String:String]()
        
        guard context >= 2, context <= 10 else {
            throw SessionError(message: "Context must be value between 2 and 10")
        }
        
        parameters["sort"] = sort.rawValue
        parameters["t"] = time.rawValue
                
        
        guard type == .link || type == .comment else {
            throw SessionError(message: "Type must be either .link or .comment")
        }
        parameters["type"] = type.rawValue

        if let after = after {
            parameters["after"] = after
        }
        
        if let before = before {
            parameters["before"] = before
        }
        
        parameters["count"] = String(count)
        
        if let limit = limit {
            parameters["limit"] = String(limit)
        }
        
        parameters["sr_detail"] = String(expandSubreddits).lowercased()
        
        let data = try await _GET(
            endpoint: "user/\(userName)/\(endPoint)",
            parameters: parameters
        )
        
        do {
            return try JSONDecoder().decode(Listing.self, from: data)
            //return redditListing
            
        } catch {
            throw SessionError(message: "Unable to decode server response.")
        }
    }
}
