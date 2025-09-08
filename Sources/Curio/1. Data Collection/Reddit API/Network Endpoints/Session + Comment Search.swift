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
    
    /// Returns a comment tree corresponding to a search of the r/subreddit/comments/article endpoint
    /// - Returns: An array of ``Listing`` objects
    func searchComment(
        subreddit: String,
        articleID: String,
        //submission: Submission,
        comment: String? = nil,
        context: UInt = 0,
        depth: Int? = nil,
        limit: Int? = nil,
        showEdits: Bool = false,
        showMedia: Bool = false,
        showMore: Bool = false,
        showTitle: Bool = false,
        sort: ListingSortOrder = .new,
        expandSubreddits: Bool = false,
        theme: RedditTheme = .light,
        threaded: Bool = false,
        truncate: UInt = 0        
    ) async throws -> [Listing] {
               
//        guard let subreddit = submission.subreddit, let articleID = submission.id
//        else {
//            throw SessionError(message: "Submission must include article data.")
//        }
        
        var parameters: [String : String] = [String:String]()
        
        if let comment = comment {
            parameters["comment"] = comment
        }
        
        parameters["context"] = String(context)
        
        if let depth = depth {
            parameters["depth"] = String(depth)
        }
        
        if let limit = limit {
            parameters["limit"] = String(limit)
        }
        
        parameters["showedits"] = String(showEdits).lowercased()
        parameters["showedia"] = String(showMedia).lowercased()
        parameters["showmore"] = String(showMore).lowercased()
        parameters["showtitle"] = String(showTitle).lowercased()
        parameters["sort"] = sort.rawValue
        parameters["sr_detail"] = String(expandSubreddits).lowercased()
        parameters["theme"] = theme.rawValue
        parameters["threaded"] = String(threaded).lowercased()
        
        guard truncate <= 50 else {
            throw SessionError(message: "Value for truncate must be between 0 and 50")
        }
        
        parameters["truncate"] = String(truncate)
        
        let data = try await _GET(
            endpoint: "r/\(subreddit)/comments/\(articleID)",
            parameters: parameters
        )
        
        do {
            return try JSONDecoder().decode([Listing].self, from: data)                     
        } catch {
            throw SessionError(message: "Unable to decode server response.")
        }
    }
}
