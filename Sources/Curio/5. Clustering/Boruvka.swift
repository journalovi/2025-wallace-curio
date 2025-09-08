//
//  Boruvka.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-10-24.
//

import Foundation
import Synchronization

extension HDBScan {
    
    func boruvkasMST<C: SNLPIndexedCorpus & Sendable>(_ corpus: C,
                                                       maxConcurrentTasks: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 2)
    ) async -> [Edge] where C.Item: Sendable {
        
        var mst: [Edge] = []
        let numVertices = Int(corpus.count)
        let uf = UnionFind(size: numVertices)
        let cheapest = SynchronizedEdgeList(count: numVertices)
        
        var numComponents = numVertices
                                
        while numComponents > 1 {
            // Reset cheapest edges.
            cheapest.reset(count: numVertices)
            
            await withTaskGroup(of: Void.self) { group in
                let chunkSize = (numVertices + maxConcurrentTasks - 1) / maxConcurrentTasks
                
                for chunkStart in stride(from: 0, to: numVertices, by: chunkSize) {
                    let chunkEnd = min(chunkStart + chunkSize, numVertices)
                    group.addTask {
                        for vertex in chunkStart..<chunkEnd {
                            var neighborLimit = self.minimumNeighbours
                            var foundCandidate = false
                            let maxLimit = max(neighborLimit, corpus.count)
                            
                            repeat {
                                
                                assert( corpus.index.count() == corpus.count )
                                
                                let neighbors = await corpus.index
                                    .find(near: corpus.encodedDocuments[vertex], limit: neighborLimit)
                                
                                //assert( neighbors.count == neighborLimit )
                                
                                for neighbor in neighbors {
                                    
                                    // Get the current representatives.
                                    let repU = uf.find(vertex)
                                    let repV = uf.find(neighbor)
                                    if repU != repV {
                                        
                                        let weight = await mutualReachabilityDistance(neighbor, vertex, corpus: corpus)
                                        let edge = Edge(a: vertex, b: neighbor, weight: weight)
                                        
                                        // Use the current representative repU as the key.
                                        cheapest.update(vertex: repU, edge: edge)
                                        foundCandidate = true
                                    }
                                }
                                if !foundCandidate {
                                    neighborLimit *= 2
                                }
                            } while (!foundCandidate && neighborLimit <= maxLimit)
                        }
                    }
                }
            }
            
            // Add the cheapest edges to the MST and union the components.
            var unionsMade = false
            for (i, edgeOptional) in cheapest.edges.enumerated() {
                
                guard uf.find(i) == i, let edge = edgeOptional else { continue }
                
                let rootA = uf.find(edge.a)
                let rootB = uf.find(edge.b)
                if rootA != rootB {
                    mst.append(edge)
                    uf.union(rootA, rootB)
                    numComponents -= 1
                    unionsMade = true
                }
            }
            
            
            // Global fallback remains as a safety net.
            if !unionsMade {
                // Collect one vertex per component.
                var repToVertex: [Int: Int] = [:]
                for vertex in 0..<numVertices {
                    let rep = uf.find(vertex)
                    repToVertex[rep] = vertex
                }
                
                let representatives = Array(repToVertex.keys)
                if representatives.count > 1 {
                    // Use the first representative as a base, and merge it with all others.
                    let base = repToVertex[representatives[0]]!
                    for rep in representatives.dropFirst() {
                        if let vertexB = repToVertex[rep] {
                            let distance = await mutualReachabilityDistance(base, vertexB, corpus: corpus)
                            let forcedEdge = Edge(a: base, b: vertexB, weight: distance)
                            print("Forcing union between vertex \(base) and vertex \(vertexB)")
                            mst.append(forcedEdge)
                            uf.union(base, vertexB)
                            numComponents -= 1
                        }
                    }
                } else {
                    print("No distinct components remain for forced union.")
                }
            }


        }
        
        return mst
    }
}
