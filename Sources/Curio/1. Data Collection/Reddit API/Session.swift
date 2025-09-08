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
//import AsyncHTTPClient

class Session {
    
    // Application ID/Token
    var client_id: String?
    var client_secret: String?
    var access_token: String? = nil
    var authResponse: AuthResponse?
    
    #if os(macOS)
    var httpHeaders: [String : String] = [
        "User-Agent" : "macOS:SwiftNLP:v0.0.1 (by /u/jimntonik)", // TODO: Create account for SwiftNLP
    ]
    #elseif os(Linux)
    var httpHeaders: [String : String] = [
        "User-Agent" : "Linux:SwiftNLP:v0.0.1 (by /u/jimntonik)", // TODO: Create account for SwiftNLP
    ]
    #endif
    
    let parameters: [String: String] = [
        "grant_type": "client_credentials"
    ]
    
    let session: URLSession = URLSession.shared
    //var httpClient: HTTPClient
    
    let baseAPIURL = "https://www.reddit.com/api/"
    let authorizedAPIURL = "https://oauth.reddit.com/"
    
    // TODO: use this information when we have multi-pronged and multi-threaded calls
    var rateLimitUsed: Int = -1
    var rateLimitRemaining: Int = -1
    var rateLimitReset: Int = -1
    
    // Create a new client with a set of
    init(id: String, secret: String) {
        client_id = id
        client_secret = secret
        //httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    }
    
//    deinit {
//        let _ = httpClient.shutdown()
//    }

}

extension Session {
    
    func fetchThread(subreddit: String, articleID: String) async throws -> RedditThread {
        
        // TODO: What are the optimal parameters for this call?
        let listings = try await searchComment(subreddit: subreddit, articleID: articleID, showMore: true)
        
        // First listing should contain our submission data
        guard listings[0].data.children[0].kind == .link else {
            throw SessionError(message: "Error, did not find initial post for this subreddit and articleID")
        }
        let submission = listings[0].data.children[0].data as! Submission
        
        // Iteratively unwrap the MoreComments results, until we're all done
        var (comments, more) = _processListingIntoCommentsAndMore(listings[1])
        
        // While we have more comments to fetch, keep making calls to the MoreChildren endpoint
        while !more.isEmpty {
            
            var toFetch: [String] = [String]()
            
            if more.count > 100 {
                toFetch = Array(more[0 ..< 100])
                more = Array(more[100 ..< more.count ])
            } else {
                toFetch = more
                more = [String]()
            }
            
            let (c2, m2) = try await moreChildren(linkID: submission.linkID, children: toFetch)
            
            // Add comments to our list of comments, add more items to our list of more items
            comments.append(contentsOf: c2)
            more.append(contentsOf: m2)
        }
        return RedditThread(submission: submission, comments: comments)
    }
    
    func _processListingIntoCommentsAndMore(_ l: Listing) -> ([Comment], [String]) {
        var comments: [Comment] = [Comment]()
        var more: [String] = [String]()
        for child in l.data.children {
            if child.kind == .comment {
                comments.append(child.data as! Comment)
            }
            if child.kind == .more {
                let moreItems = child.data as! RedditListingMore
                more.append(contentsOf: moreItems.children)
            }
        }
        return (comments,more)
    }
    
}
