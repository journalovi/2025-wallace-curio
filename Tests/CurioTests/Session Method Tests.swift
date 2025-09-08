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
import XCTest
@testable import Curio

final class RedditSessionMethodTest: XCTestCase {
    
    
    func testFetchComments() async throws {
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
        
        // "7dljcy", subreddit: "AskReddit")
        // https://www.reddit.com/r/redditdev/comments/7dohn2/why_does_the_following_api_endpoint_return/
        let result: RedditThread = try await client.fetchThread(subreddit: "AskReddit", articleID: "7dljcy") // TODO: We aren't loading all 2610 comments... some deleted, but can we tune the method to get more? 
        //print("Loaded thread with \(result.comments.count) comments")
        //print(result.submission)
        //print(result.comments[100])
        
        //TODO: This isn't a very robust test ... need to think about how we're testing these reddit endpoints more carefully
        XCTAssert(result.submission.num_comments! > 0 && result.submission.subreddit == "AskReddit")
    }
}
