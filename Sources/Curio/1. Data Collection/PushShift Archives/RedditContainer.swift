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

public protocol RedditContainer: Codable {
    associatedtype ItemType: RedditDataItem
    
    // TODO: Consolidate CommentData/SubmissionData common items into this protocol?
    var index: [String: Int32?] { get set }
    var posts: [ItemType] { get set }
    
    init (index: [String: Int32?], posts: [ItemType])
    init(_ posts: [ItemType])
    
    init(from decoder: Decoder) throws
    func encode(to encoder: Encoder) throws
}


public extension RedditContainer {
    init(_ postsToAdd: [ItemType]) {
        self.init(index: [String: Int32?](), posts: postsToAdd)
                
        for post in posts {
            self.index[post.id] = post.created_utc
        }
    }
    
    init(from decoder: Decoder) throws {
        self.init(index: [String: Int32?](), posts: [ItemType]())
        
        var container = try decoder.unkeyedContainer()
        var tmp_index: [String: Int32?]? = nil
        var elements: [ItemType] = []
        
        do {
            tmp_index = try container.decode([String: Int32].self)
        } catch {
            _ = try? container.decode(AnyDecodableValue.self)
        }
        
        while !container.isAtEnd {
            do {
                let value = try container.decode(ItemType.self)
                elements.append(value)
            } catch {
                _ = try? container.decode(AnyDecodableValue.self)
            }
        }
        
        index = if let idx = tmp_index {
            idx
        } else {
            [String: Int32?]()
        }
        
        posts = elements
    }
            
    // TODO: Currently inserts a token to end index - needs to be manually replaced with newline. How do we do this more cleanly?
    /// Encodes the data into NDJSON format, compatible with Pushshift Archives
    /// - Parameter encoder: The encoder to use
    /// - Throws: Any encoding errors
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(index)
        
        if !posts.isEmpty {
            try container.encode("[END OF INDEX]")
        }
                        
        for post in posts {
            try container.encode(post)
        }
    }
}
