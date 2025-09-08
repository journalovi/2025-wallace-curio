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

enum RedditContentType: String, CustomStringConvertible, Codable {
    case comment    = "t1"
    case account    = "t2"
    case link       = "t3"
    case message    = "t4"
    case subreddit  = "t5"
    case award      = "t6"
    case listing    = "Listing"
    case more       = "more"
        
    var description: String { rawValue }
}

enum ListingSortOrder: String, CustomStringConvertible, Codable {
    
    case relevance      = "relevance"
    case hot            = "hot"
    case top            = "top"
    case new            = "new"
    case old            = "old"
    case random         = "random"
    case qa             = "qa"
    case live           = "live"
    case comments       = "comments"
    case confidence     = "confidence"
    case controversial  = "controversial"
    
    var description: String { rawValue }
}


enum ListingTime: String, CustomStringConvertible, Codable {
    case hour   = "hour"
    case day    = "day"
    case week   = "week"
    case month  = "month"
    case year   = "year"
    case all    = "all"
    
    var description: String { rawValue }
}

enum RedditTheme: String, CustomStringConvertible, Codable {
    case dark   = "dark"
    case light  = "default"
    
    var description: String { rawValue }
}
