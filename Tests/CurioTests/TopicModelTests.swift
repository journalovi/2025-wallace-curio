#if arch(arm64)
import XCTest
import Foundation
import MLX
@testable import Curio

final class BasicTopicModelTests: XCTestCase {
    
    func testBasicTopicModel() async throws {
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("waterloo_submissions", withExtension: "zst", maxDocuments: 500, in: Bundle.module)
        print(corpus)

        let topicModel = await BasicTopicModel(corpus: corpus,
                                               clusteringAlgorithm: KMeans(numTopics: 10),
                                               reducer: UMAP(targetDimensions: 2, numNeighbours: 25, minDistance: 1.0, initialValues: .laplacian)
        )
        print(topicModel)
        await topicModel.plot(topicModelName: "BasicTopicModel_waterloo_submissions")
    }
    
    func testBERTopic() async throws{
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("waterloo_submissions", withExtension: "zst", maxDocuments: 500, in: Bundle.module)
        print(corpus)

        let topicModel = await BERTopic(corpus: corpus)
        print(topicModel)
        await topicModel.plot(topicModelName: "BERTopic_waterloo_submissions")
    }
    
    func testBasicTopicModel2() async throws {
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("waterloo_submissions", withExtension: "zst", maxDocuments: 25000, in: Bundle.module)
        //print(corpus)

        let topicModel = await BasicTopicModel(corpus: corpus,
                                               clusteringAlgorithm: HDBScan(minimumNeighbours: 25, minimumClusterSize: 3, mstConstructionMethod: .boruvka),
                                               reducer: UMAP(targetDimensions: 5, numNeighbours: 50, minDistance: 0.25, initialValues: .pca)
        )
        print(topicModel)
        await topicModel.plot(topicModelName: "BasicTopicModel_waterloo_submissions")
    }
    
}
#endif

