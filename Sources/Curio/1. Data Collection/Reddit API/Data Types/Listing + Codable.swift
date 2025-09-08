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

extension ListingDataItem {
    enum CodingKeys: String, CodingKey {
            case kind
            case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(RedditContentType.self, forKey: .kind)
        
        switch kind {
        case .comment:
            data = try container.decode(Comment.self, forKey: .data)
            
        case .link:
            data = try container.decode(Submission.self, forKey: .data)
            
        case .subreddit:
            data = try container.decode(Subreddit.self, forKey: .data)
            
        case .more:
            data = try container.decode(RedditListingMore.self, forKey: .data)
            
        default:
            throw SessionError(message: "Unknown type of Reddit content from JSON.")
        }
    }

// TODO: We don't actually need this, I'm being lazy and not implementing it
    // Custom Encoder
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)

//            switch kind {
//            case .comment:
//                guard let comment = data as? Comment else {
//                    throw EncodingError.invalidValue(data, .init(codingPath: encoder.codingPath, debugDescription: "Mismatched type for RedditComment"))
//                }
//                try container.encode(comment, forKey: .data)
//
//            case .submission:
//                guard let submission = data as? Submission else {
//                    throw EncodingError.invalidValue(data, .init(codingPath: encoder.codingPath, debugDescription: "Mismatched type for RedditSubmission"))
//                }
//                try container.encode(submission, forKey: .data)
//            }
        }
}
