#if arch(arm64)
import XCTest
import Foundation
import MLX
import MLXLMCommon
import MLXLLM
import Tokenizers
@testable import Curio

final class LLMTests: XCTestCase {
    
    func testLLM() async throws{
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("waterloo_submissions", withExtension: "zst", maxDocuments: 2000, in: Bundle.module)
        print(corpus)
        
        let topicModel = await BERTopic(corpus: corpus)
        print(topicModel)
        
        for i in 0...10 {
            print(i)
            for t in topicModel.topics {
                print(try await topicModel.summarize( t ))
            }
        }

    }
    
}
#endif

