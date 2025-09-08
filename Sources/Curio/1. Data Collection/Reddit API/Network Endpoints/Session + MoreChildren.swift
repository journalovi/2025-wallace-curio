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
    func moreChildren(
        linkID: String,
        children: [String],
        id: String? = nil,
        depth: Int? = nil,
        limitChildren: Bool = false,
        sort: ListingSortOrder = .new
    ) async throws -> ([Comment],[String]) {
               
        
        var parameters: [String : String] = [String:String]()
        parameters["api_type"] = "json"
        
        if let depth = depth {
            parameters["depth"] = String(depth)
        }
                
        parameters["sort"] = sort.rawValue
        
        parameters["children"] = children.joined(separator: ", ")
        parameters["link_id"] = linkID
        parameters["limit_children"] = String(limitChildren).lowercased()
        
        if let id = id {
            parameters["id"] = id
        }
                
        let data = try await _GET(
            endpoint: "api/morechildren",
            parameters: parameters
        )
        
        do {
            let container = try JSONDecoder().decode(MoreContainer.self, from: data)
            return _processContainer(container)
            
        } catch {
            throw SessionError(message: "Unable to decode server response.")
        }
    }
    
    func _processContainer(_ c: MoreContainer) -> ([Comment], [String]) {
        var comments: [Comment] = [Comment]()
        var more: [String] = [String]()
        
        for child in c.json.data.things {
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
