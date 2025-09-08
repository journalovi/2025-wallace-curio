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

public struct RedditListingMore: RedditDataItem {
    
    let parentId: String?
    let count: Int?
    let children: [String] // TODO: Is this the only field we need?
    
    public var id: String { return "" }            // TODO: This is a hack that allows conformance to RedditDataItem ... fix later?
    public var created_utc: Int32? { return nil } //  TODO: This is a hack that allows conformance to RedditDataItem ... fix later?
    public var subreddit: String? { return nil } //  TODO: This is a hack that allows conformance to RedditDataItem ... fix later?
}

public struct MoreContainer: Codable {
    var json: InnerMoreContainer
}

public struct InnerMoreContainer: Codable {
    let errors: [String]
    let data: InnerInnerMoreContainer
}

public struct InnerInnerMoreContainer: Codable {
    let things: [ListingDataItem]
}
