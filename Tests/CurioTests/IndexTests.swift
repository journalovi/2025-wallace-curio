#if arch(arm64)
import XCTest
import Foundation
import System
@testable import Curio


final class IndexTests: XCTestCase {
    

    func testBuildIndexedCorpus() async throws {
        var corpus = IndexedCorpus(item: Submission.self)
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 1000, in: Bundle.module)
        await corpus.buildIndex()

        XCTAssertEqual(corpus.documents.count, 1000)
    }
    
}
#endif
