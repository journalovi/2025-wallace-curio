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

public struct Comment: RedditDataItem & Sendable {
    public let author: String?
    public let author_created_utc: Int32?
    public let author_flair_css_class: String?
    public let author_flair_text: String?
    public let author_fullname: String?
    public let body: String?
    public let controversiality: Int32?
    public let created_utc: Int32?
    public let distinguished: String?
    public let gilded: Int32?
    public let id: String
    public let link_id: String?
    public let nest_level: Int32?
    public let parent_id: String?
    public let reply_delay: Int32?
    public let retrieved_on: Int32?
    public let score: Int32?
    public let score_hidden: Bool?
    public let subreddit: String?
    public let subreddit_id: String?
    public let replies: String?
    
    enum CodingKeys: String, CodingKey {
        case author = "author"
        case author_created_utc = "author_created_utc"
        case author_flair_css_class = "author_flair_css_class"
        case author_flair_text = "author_flair_text"
        case author_fullname = "author_fullname"
        case body = "body"
        case controversiality = "controversiality"
        case created_utc = "created_utc"
        case distinguished = "distinguished"
        case gilded = "gilded"
        case id = "id"
        case link_id = "link_id"
        case nest_level = "nest_level"
        case parent_id = "parent_id"
        case reply_delay = "reply_delay"
        case retrieved_on = "retrieved_on"
        case score = "score"
        case score_hidden = "score_hidden"
        case subreddit = "subreddit"
        case subreddit_id = "subreddit_id"
        case replies = "replies"
    }
}


extension Comment {
    // TODO: Handle messy data
    /// Initialize a new Comment object
    /// - Parameter decoder: The decoder to use
    /// - Throws: Any errors encountered during decoding
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        author = try container.decodeIfPresent(String.self, forKey: .author)
        author_created_utc = try container.decodeIfPresent(Int32.self, forKey: .author_created_utc)
        author_flair_css_class = try container.decodeIfPresent(String.self, forKey: .author_flair_css_class)
        author_flair_text = try container.decodeIfPresent(String.self, forKey: .author_flair_text)
        author_fullname = try container.decodeIfPresent(String.self, forKey: .author_fullname)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        controversiality = try container.decodeIfPresent(Int32.self, forKey: .controversiality)
        distinguished = try container.decodeIfPresent(String.self, forKey: .distinguished)
        gilded = try container.decodeIfPresent(Int32.self, forKey: .gilded)
        id = try container.decodeIfPresent(String.self, forKey: .id)!
        link_id = try container.decodeIfPresent(String.self, forKey: .link_id)
        nest_level = try container.decodeIfPresent(Int32.self, forKey: .nest_level)
        parent_id = try container.decodeIfPresent(String.self, forKey: .parent_id)
        reply_delay = try container.decodeIfPresent(Int32.self, forKey: .reply_delay)
        retrieved_on = try container.decodeIfPresent(Int32.self, forKey: .retrieved_on)
        score = try container.decodeIfPresent(Int32.self, forKey: .score)
        score_hidden = try container.decodeIfPresent(Bool.self, forKey: .score_hidden)
        subreddit = try container.decodeIfPresent(String.self, forKey: .subreddit)
        subreddit_id = try container.decodeIfPresent(String.self, forKey: .subreddit_id)
        replies = try container.decodeIfPresent(String.self, forKey: .replies)
        
        
        // Custom decoding for 'created_utc'
        if let createdValue = try? container.decode(Int32.self, forKey: .created_utc) {
            created_utc = createdValue
        } else if let createdString = try? container.decode(String.self, forKey: .created_utc),
                  let createdValue = Int32(createdString) {
            created_utc = createdValue
        } else {
            throw DecodingError.typeMismatch(
                Int32.self,
                DecodingError.Context(codingPath: [CodingKeys.id], debugDescription: "Expected to decode Int32 or String for created_utc")
            )
        }
    }
}

