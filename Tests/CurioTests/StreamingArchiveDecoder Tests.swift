//// Copyright (c) 2024 Jim Wallace
////
//// Permission is hereby granted, free of charge, to any person
//// obtaining a copy of this software and associated documentation
//// files (the "Software"), to deal in the Software without
//// restriction, including without limitation the rights to use,
//// copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the
//// Software is furnished to do so, subject to the following
//// conditions:
////
//// The above copyright notice and this permission notice shall be
//// included in all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//// OTHER DEALINGS IN THE SOFTWARE.
//
//import XCTest
//@testable import Curio
//
//final class StreamingArchiveDecoderTests: XCTestCase {
//            
//    
//    func testNoIndex() async throws {
//        
//        guard let submissionsURL = Bundle.module.url(forResource: "Guelph_submissions", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_submissions.zst in test bundle.")
//        }
//        
//        let stream = try StreamingArchiveDecoder<Submission>(input: submissionsURL)
//        
//        XCTAssert(stream.memoryStore!.count == 17999)
//        XCTAssert(stream.errorStore.count == 0)
//    }
//    
//    func testNoIndexBig() async throws {
//        
//        guard let submissionsURL = Bundle.module.url(forResource: "Guelph_submissions", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_submissions.zst in test bundle.")
//        }
//        guard let commentsURL = Bundle.module.url(forResource: "Guelph_comments", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_submissions.zst in test bundle.")
//        }
//                
//        let sStream = try StreamingArchiveDecoder<Submission>(input: submissionsURL)
//        let cStream = try StreamingArchiveDecoder<Comment>(input: commentsURL)
//                
//        XCTAssert(sStream.memoryStore!.count == 17999)
//        XCTAssert(sStream.errorStore.count == 0)
//        XCTAssert(cStream.memoryStore!.count == 160104)
//        XCTAssert(cStream.errorStore.count == 0)
//    }
//    
//    func testIndex() async throws {
//
//        guard let submissionsURL = Bundle.module.url(forResource: "RS_2006-01", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_submissions.zst in test bundle.")
//        }
//        
//        let stream = try StreamingArchiveDecoder<Submission>(input: submissionsURL)
//
//        XCTAssert(stream.memoryStore!.count == 8048)
//        XCTAssert(stream.errorStore.count == 0)
//
//    }
//    
//    func testIndexBig() async throws {
//        
//        guard let submissionsURL = Bundle.module.url(forResource: "waterloo_submissions", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_submissions.zst in test bundle.")
//        }
//        guard let commentsURL = Bundle.module.url(forResource: "waterloo_comments", withExtension: "zst") else {
//            fatalError("Failed to find waterloo_comments.zst in test bundle.")
//        }
//        
//        
//        let sStream = try StreamingArchiveDecoder<Submission>(input: submissionsURL)
//        let cStream = try StreamingArchiveDecoder<Comment>(input: commentsURL)
//                        
//        XCTAssert(sStream.memoryStore!.count == 8048)
//        XCTAssert(sStream.errorStore.count == 0)
//        XCTAssert(cStream.memoryStore!.count == 3666)
//        XCTAssert(cStream.errorStore.count == 0)
//    }
//    
//    func testFilter() async throws {
//        
//        guard let submissionsURL = Bundle.module.url(forResource: "Guelph_submissions", withExtension: "zst") else {
//            fatalError("Failed to find Guelph_submissions.zst in test bundle.")
//        }
//        
//        let filter: (Submission) -> Bool = { value in
//            if let selftext = value.selftext {
//                if selftext.contains("university") {
//                    return true
//                }
//            }
//            return false
//        }
//
//        let stream = try StreamingArchiveDecoder(input: submissionsURL, filter: filter)
//        
//        XCTAssert(stream.memoryStore!.count == 139)
//        XCTAssert(stream.errorStore.count == 0)
//    }
//
//}
