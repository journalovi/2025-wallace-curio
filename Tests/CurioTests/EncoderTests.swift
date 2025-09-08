// MLX Requires an M-Series Mac, CI/DI server is Intel
#if arch(arm64)


import XCTest
import Foundation
import Tokenizers
@testable import Curio

final class EncoderTests: XCTestCase {
    
    func testM2VEncoder() async throws {
                
        var corpus = await InMemoryCorpus(item: Submission.self, encoder: M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
                
        XCTAssert(corpus.documents.count == 100)
        
        for (idx, _) in corpus.documents.enumerated() {
            let encodedDocument = corpus.encodedDocuments[idx]
            XCTAssert( !encodedDocument.allSatisfy{ $0 == 0 } )
        }
    }

    
    func testCoreMLEncoder() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: CoreMLEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
        
        for (idx, _) in corpus.documents.enumerated() {
            let encodedDocument = corpus.encodedDocuments[idx]
            XCTAssert( !encodedDocument.allSatisfy{ $0 == 0 } )
        }
    }
    
    
    func testNaturalLanguageEncoder() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: NaturalLanguageEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100,in: Bundle.module)
        
        XCTAssert(corpus.documents.count == 100)
        
        for (idx, _) in corpus.documents.enumerated() {
            let encodedDocument = corpus.encodedDocuments[idx]
            XCTAssert( !encodedDocument.allSatisfy{ $0 == 0 } )
        }
    }
}

#endif
