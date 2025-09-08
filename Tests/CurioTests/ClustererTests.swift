//
//  HNSWDBscanTests.swift
//  SwiftNLP
//
//  Created by Mingchung Xia on 2024-09-22.
//

#if arch(arm64)

import XCTest
@testable import Curio

final class ClustererTests: XCTestCase {
    
    
    func testKMeans() async throws {
                
        var corpus = await IndexedCorpus(item: Submission.self, encoder: M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 500, in: Bundle.module)
        await corpus.buildIndex()
                
        var kmeans = KMeans(numTopics: 10)
        
        var (clusters, unknown) = await kmeans.getClusters(corpus)
        
        if let unknown = unknown {
            clusters.append(unknown)
        }
        
        XCTAssert(clusters.count  > 0)
    }
    
    func testDBSCAN() async throws {
                            
        var corpus = await IndexedCorpus(item: Submission.self, encoder: M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 500, in: Bundle.module)
        await corpus.buildIndex()
                        
        var DBSCAN = DBScan(eps: 1.0, minNeighbours: 5)

        var (clusters, unknown) = await DBSCAN.getClusters(corpus)
        
        if let unknown = unknown {
            clusters.append(unknown)
        }
        
        XCTAssert(clusters.count  > 0)
    }
    
    func testHDBSCAN() async throws {
                            
        var corpus = await IndexedCorpus(item: Submission.self, encoder: M2VEncoder(), metric: AngularDistance())
        await corpus.loadFromBundledNDJSONArchive("Guelph_submissions", withExtension: "zst", maxDocuments: 500, in: Bundle.module)
        await corpus.buildIndex()        
                        
        var HDBSCAN = HDBScan(minimumNeighbours: 5, minimumClusterSize: 15)

        var (clusters, unknown) = await HDBSCAN.getClusters(corpus)
                
        if let unknown = unknown {
            clusters.append(unknown)
        }
        
        XCTAssert(clusters.count  > 0)
    }
    
    
}

#endif
