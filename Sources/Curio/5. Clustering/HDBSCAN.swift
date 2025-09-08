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

import Foundation
import HeapModule
import SimilarityMetric
import MLX

public struct HDBScan: SNLPClusteringAlgorithm {
    /// The number of nearest neighbors to consider
    public var minimumNeighbours: Int = 15
    
    /// The minimum number of points in a cluster
    public var minimumClusterSize: Int = 25
    
    // Cache
    public var coreDistanceCache: DistanceCache
    
    /// The minimum distance between two points
    //public var metric: any DistanceMetric = EuclideanDistance()
    
    /// The method to use for constructing the MST
    public enum mstAlgorithm: Sendable {
        case vanilla
        case boruvka
    }
    
    var mstConstructionMethod: mstAlgorithm
    
    /// Constructor that allows for initialization of all parameters
    init(minimumNeighbours: Int,
         minimumClusterSize: Int,
         mstConstructionMethod: mstAlgorithm = .boruvka) {
        self.minimumNeighbours = minimumNeighbours
        self.minimumClusterSize = minimumClusterSize
        self.mstConstructionMethod = mstConstructionMethod
        self.coreDistanceCache = DistanceCache()
    }
    
    /// Clusters the given corpus using the HDBSCAN algorithm
    /// - Parameters:
    ///   - corpus: The corpus to cluster
    /// - Returns: A tuple containing the clusters and any outliers
    mutating func getClusters<C: SNLPIndexedCorpus>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?) {

        //self.metric = corpus.metric
        
        // Step 1. Create our (approximate) MST
        var mst = [Edge]()
        switch mstConstructionMethod {
        case .vanilla:
            mst = await approximateMinimalSpanningTree(corpus)
        case .boruvka:
            mst = await boruvkasMST(corpus)
        }
        
        let d = Dendrogram(mst)
        makeDendrogramPlot(dendrogram: d, dataSetName: "HDBSCAN")
        //makeMSTPlot(data: corpus.encodedDocuments, mst: mst, dataSetName: "MST")
        
        d.condense(minClusterSize: minimumClusterSize)
        
        //d.printDendrogram()
        let stableClusters = d.extractClusters()
        
        var clusters = [[Int]]()
        var allUnion: Set<Int> = []
        for cluster in stableClusters {
            clusters.append(cluster.points.map { $0 })
            allUnion.formUnion(cluster.points)
        }
        
        let unknown = Array(Set(0...Int(corpus.count-1)).subtracting(allUnion))
        
                
        return (clusters, unknown)
    }
    
    /// Computes the mutual reachability distance between two points
    /// - Parameters:
    ///   - from: The first point
    ///   - to: The second point
    ///   - corpus: The corpus containing the points
    /// - Returns: The mutual reachability distance between the two points
    @inlinable
    internal func mutualReachabilityDistance<C: SNLPIndexedCorpus>(_ from: Int, _ to: Int, corpus: C) async -> Double {
        return max(
            await coreDistance(from, corpus: corpus),
            await coreDistance(to, corpus: corpus),
            corpus.metric.distance(between: corpus.encodedDocuments[from], corpus.encodedDocuments[to])
        )
    }
    
    /// Computes the core distance of a point
    /// - Parameters:
    ///   - point: The point to compute the core distance for
    ///   - corpus: The corpus containing the point
    /// - Returns: The core distance of the point
    @inlinable
    internal func coreDistance<C: SNLPIndexedCorpus>(_ point: Int, corpus: C) async -> Double {
                
        if let cachedValue = coreDistanceCache[point] {
            return cachedValue
        }
        
        let kNN = await corpus.index.find(near: corpus.encodedDocuments[point], limit: minimumNeighbours).filter{ $0 != -1 }
        if kNN.isEmpty { return .greatestFiniteMagnitude }
        let newValue = corpus.metric.distance(between: corpus.encodedDocuments[point], corpus.encodedDocuments[kNN.last!])

        coreDistanceCache[point] = newValue
        
        return newValue
        
    }
    
    /// Approximates the minimal spanning tree of the corpus
    /// - Parameter corpus: The corpus to construct the MST for
    /// - Returns: The edges of the MST
    @inlinable
    func approximateMinimalSpanningTree<C: SNLPIndexedCorpus>(_ corpus: C) async -> [Edge] {
        guard corpus.count > 0 else { return [] }
        
        var mst: [Edge] = []
        var visited = Set<Int>()
        var priorityQueue = Heap<Edge>()
        
        
        // Start with the first item in the corpus ...
        let startIndex = Int.random(in: 0..<Int(corpus.count))
        visited.insert(startIndex)
        let neighbours = await corpus.index.find(near: corpus.encodedDocuments[startIndex], limit: minimumNeighbours).filter{ $0 != -1 }
        
        for neighbour in neighbours {
            let distance = await mutualReachabilityDistance(neighbour, startIndex, corpus: corpus)
            priorityQueue.insert(Edge(a: startIndex,b: neighbour,weight: distance))
        }
        
        // While we haven't visited every point in the data set
        while visited.count < corpus.count {
            
            // If our priority queue is empty, search for the optimal edge from any visited node to any unvisited node.
            if priorityQueue.count == 0 {

                var bestEdge: Edge? = nil
                let unvisited = (0..<corpus.encodedDocuments.count).filter { !visited.contains($0) }

                for unvisitedIndex in unvisited {
                    for visitedIndex in visited {
                        let distance = await mutualReachabilityDistance(unvisitedIndex, visitedIndex, corpus: corpus)
                        if bestEdge == nil || distance < bestEdge!.weight {
                            bestEdge = Edge(a: visitedIndex, b: unvisitedIndex, weight: distance)
                        }
                    }
                }
                
                if let bestEdge = bestEdge {
                    priorityQueue.insert(bestEdge)
                }
            }

            
            let minEdge = priorityQueue.removeMin()
            
            if visited.contains(minEdge.b) {
                continue // Skip this if the node has already been visited
            }
            
            // Add this edge to our MST
            mst.append(minEdge)
            visited.insert(minEdge.b)
            
            // Get neighbours for newly visited node, make sure we find at least one unvisited neighbour
            var unvisitedNeighbors: [Int] = []
            var tmpK = minimumNeighbours
            repeat {
                unvisitedNeighbors = await corpus.index.find(near: corpus.encodedDocuments[minEdge.b], limit: tmpK).filter { $0 != -1 && !visited.contains($0) }
                tmpK *= 2
            } while unvisitedNeighbors.count == 0 && tmpK < Int(corpus.count/2)
            
            //let neighbours = corpus.index.find(near: corpus.encodedDocuments[_offset: minEdge.b], limit: k)
            
            for neighbour in unvisitedNeighbors {
                let distance = await mutualReachabilityDistance(neighbour, minEdge.b, corpus: corpus)
                priorityQueue.insert( Edge(a: minEdge.b,b: neighbour,weight: distance))
                
            }
            
        }
        
        // If we are out of points, we have finished creating our MST
        return mst
    }
}
