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
//
// Download from: https://reddit-top20k.cworld.ai/
// e.g. https://reddit-archive.cworld.ai/AskReddit_submissions.zst
// e.g. https://reddit-archive.cworld.ai/AskReddit_comments.zst

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias SubredditData = [String : RedditThread]
public typealias SubredditID = String

/// Load data from a Reddit Archive
/// - Parameters:
///   - data: Data to load
///   - source: The source of the data (URL)
///   - verbose: Whether to print debug information
/// - Returns: Tuple with submissions and error data as ``SubredditData``
public func downloadSubredditFromServer(subreddit: String, source: String = "https://reddit-archive.cworld.ai/", verbose: Bool = false) async throws -> SubredditData {
    
    // TODO: Add another server? e.g., https://the-eye.eu/redarcs/files/
    
    var result: SubredditData = [String : RedditThread]()
    
    let submissionsURL = source + subreddit + "_submissions.zst"
    let commentsURL = source + subreddit + "_comments.zst"
    
    //debugPrint("Downloading \(submissionsURL)")
    //debugPrint("Downloading \(commentsURL)")
    
    if let submissionsURL = URL(string: submissionsURL),
        let commentsURL = URL(string: commentsURL) {
        do {
            
            // Download and process submissions and comments
            async let submissionsData = try Data(contentsOf: submissionsURL)
            async let commentsData = try Data(contentsOf: commentsURL)
            
            
            // Once we have submissions data,
            let _ = try await submissionsData
            //debugPrint("Processing submission data...")
            let (submissions, _ ): ([Submission],[Data]) = try await loadFromRedditArchive(submissionsData, verbose: verbose) // TODO: Figure out what to do with error data
            for submission in submissions {
                // Create a new thread for each submission, index by submission ID
                result["t3_\(submission.id)"] = RedditThread(submission: submission, comments: [Comment]())
            }
            //debugPrint("Completed processing submissions.")

            // Then fill in the comments once we have them..
            let _ = try await commentsData
            //debugPrint("Processing comments data...")
            let (comments, _ ): ([Comment],[Data]) = try await loadFromRedditArchive(commentsData, verbose: verbose) // TODO: Figure out what to do with error data
            for comment in comments {
                if result[comment.link_id!] != nil {
                    result[comment.link_id!]!.add(comment)
                }
            }
            //debugPrint("Completed processing comments.")

        } catch {
            print("Error downloading or loading data: \(error)")
            return result
        }
    }
    
    return result
}


/// Load submissions data
/// - Parameters:
///   - subreddit: The subreddit to download
///   - source: The source of the data (URL)
///   - verbose: Whether to print debug information
/// - Returns: An array of ``Submission`` objects
public func downloadSubmissionsFromServer(subreddit: String, source: String = "https://reddit-archive.cworld.ai/", verbose: Bool = false) async throws -> [Submission] {
    
    var result = [Submission]()
    
    let submissionsURL = source + subreddit + "_submissions.zst"
    debugPrint("Downloading \(submissionsURL)")
    
    if let submissionsURL = URL(string: submissionsURL) {
        do {
            
            // Download and process submissions and comments
            async let submissionsData = try Data(contentsOf: submissionsURL)
                                    
            // Once we have submissions data,
            let _ = try await submissionsData
            debugPrint("Processing submission data...")
            let (submissions, _ ): ([Submission],[Data]) = try await loadFromRedditArchive(submissionsData, verbose: verbose) // TODO: Figure out what to do with error data
            debugPrint("Completed processing submissions.")
            
            result = submissions

        } catch {
            print("Error downloading or loading data: \(error)")
            return result
        }
    }
    return result
}

/// Load comments data
/// - Parameters:
///   - subreddit: The subreddit to download
///   - source: The source of the data (URL)
///   - verbose: Whether to print debug information
/// - Returns: An array of ``Comment`` objects
public func downloadCommentsFromServer(subreddit: String, source: String = "https://reddit-archive.cworld.ai/", verbose: Bool = false) async throws -> [Comment] {
    
    var result = [Comment]()
    
    let commentsURL = source + subreddit + "_comments.zst"
    debugPrint("Downloading \(commentsURL)")
    
    if let commentsURL = URL(string: commentsURL) {
        do {
            
            // Download and process submissions and comments
            async let commentsData = try Data(contentsOf: commentsURL)
                                    
            // Once we have submissions data,
            let _ = try await commentsData
            debugPrint("Processing submission data...")
            let (comments, _ ): ([Comment],[Data]) = try await loadFromRedditArchive(commentsData, verbose: verbose) // TODO: Figure out what to do with error data
            debugPrint("Completed processing comments.")
            
            result = comments

        } catch {
            print("Error downloading or loading data: \(error)")
            return result
        }
    }
    return result
}
