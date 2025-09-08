// MLX Requires an M-Series Mac, CI/DI server is Intel
#if arch(arm64)


import XCTest
import Foundation
@testable import Curio

final class CorpusTests: XCTestCase {
    
    func testCorpusCopy() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: CoreMLEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 10, in: Bundle.module)
        
        var copy = corpus.copy()
        XCTAssert(corpus.documents.count == 10)
        XCTAssert(copy.documents.count == 10)
        
        XCTAssert( !copy.encodedDocuments.allSatisfy{ $0.allSatisfy{ $0 == 0 } } )
        copy.encodedDocuments[0] = copy.documentEncoder.zeroes
        XCTAssert( !corpus.encodedDocuments.allSatisfy{ $0.allSatisfy{ $0 == 0 } } )
        
    }
}

#endif
