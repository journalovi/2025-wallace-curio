// MLX Requires an M-Series Mac, CI/DI server is Intel
#if arch(arm64)


import XCTest
import Foundation
import Tokenizers
@testable import Curio

final class ReducerTests: XCTestCase {
    
    func testTruncatingReducer() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 512)
        
        let tr = TruncatingReducer(targetDimensions: 10)
        
        var mlx = corpus.encodedDocumentsAsMLXArray
        tr.reduce(&mlx)
        corpus.encodedDocumentsAsMLXArray = mlx
                
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }
    
    func testPCA() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
                
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions > 10)
        
        let pca = PCA(targetDimensions: 10)
        
        var mlx = corpus.encodedDocumentsAsMLXArray
        pca.reduce(&mlx)
        corpus.encodedDocumentsAsMLXArray = mlx
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }
    
    func testLaplacian() async throws {
                
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
        await corpus.buildIndex()
                
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions > 10)
        
        let fsc = await FuzzySimplicialComplex(corpus, k: 15)
        //print(fsc)
        
        let laplacian = LaplacianReducer(targetDimensions: 10, fsc: fsc)
        
        var mlx = corpus.encodedDocumentsAsMLXArray
        laplacian.reduce(&mlx)
        corpus.encodedDocumentsAsMLXArray = mlx
        
        print(mlx.shape)
        //print(corpus.encodedDocuments.shape)
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }
    
    func testTSNE() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
                
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions > 10)
        
        let tsne = tSNE(targetDimensions: 10, initialValues: .laplacian)
        
        await tsne.reduceCorpus(&corpus)       
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }

    func testSTSNE() async throws {
                
        var corpus = InMemoryCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
                
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions > 10)
        
        let stsne = StSNE(targetDimensions: 10)
        
        await stsne.reduceCorpus(&corpus)
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }
    
    func testUMAP() async throws {
                
        var corpus = IndexedCorpus(item: Submission.self, encoder: await M2VEncoder())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 100, in: Bundle.module)
        await corpus.buildIndex()
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions > 10)
        
        let umap = UMAP(targetDimensions: 10)
        
        await umap.reduceCorpus(&corpus)
        
        XCTAssert(corpus.count == 100)
        XCTAssert(corpus.dimensions == 10)
    }
}

#endif
