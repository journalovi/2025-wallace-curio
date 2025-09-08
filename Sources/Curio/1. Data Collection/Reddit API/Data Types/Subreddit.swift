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

public struct Subreddit: RedditDataItem {
    public var id: String
    public let submitText: String?
    public let displayName: String?
    public let headerImage: String?
    public let descriptionHTML: String?
    public let title: String?
    public let collapseDeletedComments: Bool
    public let over18: Bool
    public let publicDescriptionHTML: String?
    public let headerTitle: String?
    public let description: String?
    public let accountsActive: UInt?
    public let publicTraffic: Bool
    public let subscribers: UInt?
    public let created: Int?
    public let url: String?
    public let createdUTC: Int
    public let publicDescription: String?
    
    public var created_utc: Int32? { Int32(createdUTC) }
    public var subreddit: String? { displayName }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case submitText = "submit_text"
        case displayName = "display_name"
        case headerImage = "header_image"
        case descriptionHTML = "description_html"
        case title = "title"
        case collapseDeletedComments = "collapse_deleted_comments"
        case over18 = "over18"
        case publicDescriptionHTML = "public_description_html"
        case headerTitle = "header_title"
        case description = "description"
        case accountsActive = "accounts_active"
        case publicTraffic = "public_traffic"
        case subscribers = "subscribers"
        case created = "created"
        case url = "url"
        case createdUTC = "created_utc"
        case publicDescription = "public_description"
    }
}
