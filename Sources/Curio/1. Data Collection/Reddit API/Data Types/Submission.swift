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

// TODO: use coding keys to refactor these fields as more Swifty
public struct Submission: RedditDataItem & Sendable {
    public let author: String?
    public let author_flair_css_class: String?
    public let author_flair_text: String?
    public let created_utc: Int32?
    public let domain: String?
    public let full_link: String?
    public let id: String
    public let is_self: Bool?
    internal let media_embed: AnyDecodableValue? // FIXME: Revisit this later
    public let num_comments: Int32?
    public let over_18: Bool?
    public let permalink: String?
    public let score: Int32?
    public let hide_score: Bool?
    public let selftext: String?
    public let subreddit: String?
    public let subreddit_id: String?
    public let thumbnail: String?
    public let title: String?
    public let url: String?
    
    public var linkID: String {
        "\(RedditContentType.link)_\(String(describing: id))"
    }
    
    enum CodingKeys: String, CodingKey {
        case author = "author"
        case author_flair_css_class = "author_flair_css_class"
        case author_flair_text = "author_flair_text"
        case created_utc = "created_utc"
        case domain = "domain"
        case full_link = "full_link"
        case id = "id"
        case is_self = "is_self"
        case media_embed = "media_embed"
        case num_comments = "num_comments"
        case over_18 = "over_18"
        case permalink = "permalink"
        case score = "score"
        case hide_score = "hide_score"
        case selftext = "selftext"
        case subreddit = "subreddit"
        case subreddit_id = "subreddit_id"
        case thumbnail = "thumbnail"
        case title = "title"
        case url = "url"
    }

}

extension Submission {
    
    /// Initializes a RedditSubission with whatever information is provided, makes all other fields nil
    public init(author: String? = nil,
                author_flair_css_class: String? = nil,
                author_flair_text: String? = nil,
                created_utc: Int32? = nil,
                domain: String? = nil,
                full_link: String? = nil,
                id: String? = nil,
                is_self: Bool? = nil,
                num_comments: Int32? = nil,
                over_18: Bool? = nil,
                permalink: String? = nil,
                score: Int32? = nil,
                hide_score: Bool? = nil,
                selftext: String? = nil,
                subreddit: String? = nil,
                subreddit_id: String? = nil,
                thumbnail: String? = nil,
                title: String? = nil,
                url: String? = nil) 
    {
        self.author = author
        self.author_flair_css_class = author_flair_css_class
        self.author_flair_text = author_flair_text
        self.created_utc = created_utc
        self.domain = domain
        self.full_link = full_link
        self.id = id!
        self.is_self = is_self
        self.media_embed = nil
        self.num_comments = num_comments
        self.over_18 = over_18
        self.permalink = permalink
        self.score = score
        self.hide_score = hide_score
        self.selftext = selftext
        self.subreddit = subreddit
        self.subreddit_id = subreddit_id
        self.thumbnail = thumbnail
        self.title = title
        self.url = url
    }
    
    
    // TODO: Handle messy data
    /// Initialize a new Submission object
    /// - Parameter decoder: The decoder to use
    /// - Throws: Any errors encountered during decoding
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        author = try container.decodeIfPresent(String.self, forKey: .author)
        author_flair_css_class = try container.decodeIfPresent(String.self, forKey: .author_flair_css_class)
        author_flair_text = try container.decodeIfPresent(String.self, forKey: .author_flair_text)
        
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        full_link = try container.decodeIfPresent(String.self, forKey: .full_link)
        id = try container.decodeIfPresent(String.self, forKey: .id)!
        is_self = try container.decodeIfPresent(Bool.self, forKey: .is_self)
        // For media_embed, you need to handle the decoding based on how AnyDecodableValue is implemented
        media_embed = nil
        num_comments = try container.decodeIfPresent(Int32.self, forKey: .num_comments)
        over_18 = try container.decodeIfPresent(Bool.self, forKey: .over_18)
        permalink = try container.decodeIfPresent(String.self, forKey: .permalink)
        score = try container.decodeIfPresent(Int32.self, forKey: .score)
        hide_score = try container.decodeIfPresent(Bool.self, forKey: .hide_score)
        selftext = try container.decodeIfPresent(String.self, forKey: .selftext)
        subreddit = try container.decodeIfPresent(String.self, forKey: .subreddit)
        subreddit_id = try container.decodeIfPresent(String.self, forKey: .subreddit_id)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        
        // Custom decoding for 'created_utc'
        //created_utc = try container.decodeIfPresent(Int32.self, forKey: .created_utc)
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
