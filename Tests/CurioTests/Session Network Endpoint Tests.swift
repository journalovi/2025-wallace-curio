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

final class RedditSessionEndpointTest: XCTestCase {
    
    
    func testHasRedditCredentials() throws {
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
                
        XCTAssertNotNil(id)
        XCTAssertNotNil(secret)
    }
    
    func testRedditAuth() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        // We don't ever want to show these ... they are secrets
        //debugPrint("Client ID: \(id)")
        //debugPrint("Secret: \(secret)")
        
        let client = Session(id: id, secret: secret)
        let response = try await client.authenticate()
        
        //let success = String(data: response, encoding: .utf8)!
//        if response {
//            debugPrint(client.authResponse?.access_token ?? "Access token not received.")
//        } else {
//            debugPrint("Authentication failed")
//        }
        
        XCTAssertEqual(response, true)
        XCTAssertNotNil(client.authResponse)
    }
    
    func test_GET() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
                
        let searchParameters = ["q" : "puppies"]        
        let result = try await client._GET(endpoint: "subreddits/search", parameters: searchParameters)
        
        XCTAssert(!result.isEmpty)
        //XCTAssertEqual(response.statusCode, 200)
        //XCTAssertNotNil(client.authResponse)
    }
    
    
    func testSubredditAbout() async throws {
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
        
        let result: Subreddit = try await client.aboutSubreddit("uwaterloo")

        XCTAssert(result.displayName == "uwaterloo" && result.title == "University of Waterloo")
    }
    
    func testSubredditSearch() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
        
        let result: Listing = try await client.searchSubreddit("uwaterloo", query: "goose", limit: 100)
               
        XCTAssert(result.data.children.count > 0)
    }
    
    func testCommentSearch() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
        
        // https://www.reddit.com/r/uwaterloo/comments/18lbokl/conestoga_college_finally_being_called_out_by_the/
        //let submission = Submission(id: "18lbokl", subreddit: "uwaterloo")
        
        // This should return an array of listings, one with original submisison and one with responses.
        let result = try await client.searchComment(subreddit: "uwaterloo", articleID: "18lbokl")
        
        
        XCTAssert(result.count > 0)
        //XCTAssert(result[1].children.count > 0)
    }
    
    func testCommentSearchWithMoreChildren() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
        
        // 1) https://www.reddit.com/r/AmItheAsshole/comments/18m3xgr/aita_for_refusing_to_attend_my_inlaws_christmas/
        // 2) https://www.reddit.com/r/AskReddit/comments/7dljcy/serious_what_can_the_average_joe_do_to_save_net/.json
        //let submission = Submission(id: "7dljcy", subreddit: "AskReddit")
        
        // This should return an array of listings, one with original submisison and one with responses.
        // It's a big thread, so we *should* also get a `more` entry
        let result = try await client.searchComment(subreddit: "AskReddit", articleID: "7dljcy", showMore: true)
                        
        XCTAssert(result.count > 0)
        //XCTAssert(result[1].children.count > 0)
    }
    
    func testUserSearch() async throws {
        
        let id = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? nil
        let secret = ProcessInfo.processInfo.environment["REDDIT_CLIENT_SECRET"] ?? nil
        
        guard let id = id, let secret = secret else {
            fatalError("Unable to fetch REDDIT_CLIENT_ID and REDDIT_CLIENT_SECRET from ProcessInfo.")
        }
        
        let client = Session(id: id, secret: secret)
        guard let _ = try? await client.authenticate() else {
            throw SessionError(message: "Error authenticating client.")
        }
               
        let overviewResult = try await client.searchUserOverview(userName: "jimntonik")
        XCTAssert(overviewResult.data.children.count > 0)
        
        let submittedResult = try await client.searchUserSubmitted(userName: "jimntonik")
        XCTAssert(submittedResult.data.children.count > 0)
        
        let commentResult = try await client.searchUserComments(userName: "jimntonik")
        XCTAssert(commentResult.data.children.count > 0)
        
        //let upvotedResult = try await client.searchUserUpvoted(userName: "jimntonik") // TODO: 403 - Forbidden - requires login?
        //XCTAssert(upvotedResult.children.count > 0)
        
        //let downvotedResult = try await client.searchUserDownvoted(userName: "jimntonik") // TODO: 403 - Forbidden - requires login?
        //XCTAssert(downvotedResult.children.count > 0)
        
        //let hiddenResult = try await client.searchUserHidden(userName: "jimntonik") // TODO: 403 - Forbidden - requires login?
        //XCTAssert(hiddenResult.children.count > 0)
        
        //let savedResult = try await client.searchUserSaved(userName: "jimntonik") // TODO: 403 - Forbidden - requires login?
        //XCTAssert(savedResult.children.count > 0)
        
        //let gildedResult = try await client.searchUserGilded(userName: "jimntonik") // TODO: 403 - Forbidden - requires login?
        //XCTAssert(gildedResult.children.count > 0)
    }
}
