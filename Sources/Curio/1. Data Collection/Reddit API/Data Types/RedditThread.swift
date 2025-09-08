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

public struct RedditThread: SNLPDataItem {
    
    public let submission: Submission
    public var comments: [Comment]
    
    public var id: String { submission.id }
    public var createdOn: Date { Date(timeIntervalSince1970: TimeInterval(submission.created_utc ?? 0)) }
    public var fullText: String {
        let commentsText = comments.map { $0.fullText }.joined(separator: " ")
        return [submission.selftext, commentsText].compactMap { $0 }.joined(separator: " ")
    }
    
    public var count: Int { comments.count + 1 }
}



extension RedditThread {
    /// Returns if the thread contains a comment with a given ID
    /// - Parameter idToFind: The ID of the comment to find
    /// - Returns: A boolean indicating if the thread contains a comment with the given ID
    @inlinable
    public func containsID(_ idToFind: String) -> Bool {
        if submission.id == idToFind {
            return true
        }
        
        for comment in comments {
            if comment.id == idToFind {
                return true
            }
        }
            
        return false
    }
    
    /// Returns if the thread contains a comment with a given text
    /// - Parameter textToFind: The text to find in the thread
    /// - Returns: A boolean indicating if the thread contains the given text
    @inlinable
    public func containsText(_ textToFind: String) -> Bool {
        if submission.title!.contains(textToFind) || submission.selftext!.contains(textToFind) {
            return true
        }
        
        for comment in comments {
            if let body = comment.body, body.contains(textToFind) {
                return true
            }
        }
            
        return false
    }
     
    /// Adds a ``Comment`` to the thread
    /// - Parameter comment: The comment to add
    @inlinable
    public mutating func add(_ comment: Comment) {
        comments.append(comment)
    }
}
