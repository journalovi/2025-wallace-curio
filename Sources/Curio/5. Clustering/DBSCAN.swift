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
import MLX
import OrderedCollections
import SimilarityMetric

public struct DBScan: SNLPClusteringAlgorithm {
    
    /// The maximum distance between two samples for one to be considered as in the neighborhood of the other
    private var eps: Double
    
    /// The number of samples in a neighborhood for a point to be considered as a core point
    private var minNeighbours: Int
    
    /// The distance metric to use
    //internal var metric: any DistanceMetric
        
    /// Creates a new clustering algorithm with the specified values
    /// - Parameters:
    ///   - eps: The maximum distance between two samples for one to be considered as in the neighborhood of the other.
    ///   - minNeighbours: The number of samples in a neighborhood for a point to be considered as a core point.
    ///   - distanceMetric: The distance metric to use.
    public init(eps: Double, minNeighbours: Int) {
        self.eps = eps
        self.minNeighbours = minNeighbours
        //self.metric = CartesianDistance()
    }
    
    /// Clusters the provided corpus and returns the clusters and outliers
    /// - Parameter corpus: The corpus to cluster
    /// - Returns: The clusters and outliers as `[Int]`
    mutating func getClusters<C: SNLPIndexedCorpus>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?) {
                       
        // Set the limit to the typical neighborhood size of the HNSW (the number of expected neighbours of a point)
        // limit = nil might also be valid
        let limit = minNeighbours // TODO: FIX!
        var currentLabel = 0
        let mlx = corpus.encodedDocumentsAsMLXArray
        
        // Create a list to store all Points, indexed by their position in the documents list
        var points: [Point] = []
        
        // Initialize Points for all documents with their index as a unique identifier
        for (idx, document) in mlx.enumerated() {
            let point = Point( document, index: idx)
            points.append(point)
        }
        
        // Keep track of visited points
        var visitedPoints = Set<Int?>()
        
        for point in points where point.label == nil {
            defer { visitedPoints.insert(point.index) }
            
            // Get approximate neighbors of the point
            var neighbours: [Point] = []
            
            let neighbourhood = await corpus.index.find(near: point.value, limit: limit)
            
            for neighbour in neighbourhood {

                if corpus.metric.distance(between: point.value, mlx[neighbour]) < eps {
                    // Find the index of this neighbour in the original document list
                    if !visitedPoints.contains(neighbour) {
                        let neighborPoint = points[neighbour]
                        neighbours.append(neighborPoint)
                    }
                }
            }
            
            // If the point has enough neighbors, it's a core point
            if neighbours.count >= self.minNeighbours {
                defer { currentLabel += 1 }
                point.label = currentLabel
                
                while !neighbours.isEmpty {
                    let neighbour = neighbours.removeFirst()
                    
                    guard neighbour.label == nil else { continue }
                    defer { visitedPoints.insert(neighbour.index) }
                    
                    neighbour.label = currentLabel
                    
                    // Find neighbors of this neighbor
                    var neighbourNeighbours: [Point] = []
                    let neighbourNeighbourhood = await corpus.index.find(near: neighbour.value, limit: limit)
                    
                    for neighbourNeighbour in neighbourNeighbourhood {
                        if corpus.metric.distance(between: neighbour.value, mlx[neighbourNeighbour]) < eps {
                            // Find the index of this neighbour's neighbour
                              if !visitedPoints.contains(neighbourNeighbour) {
                                let neighbourPoint = points[neighbourNeighbour]
                                neighbourNeighbours.append(neighbourPoint)
                            }
                        }
                    }
                    
                    // Only add to the list if this neighbour is a core point
                    if neighbourNeighbours.count >= self.minNeighbours {
                        neighbours.append(contentsOf: neighbourNeighbours)
                    }
                }
            }
        }
        
        // Post-processing
        let groupings = Dictionary(grouping: points, by: { $0.label })
        
        var clusters: [[Int]] = []
        var outliers: [Int] = []
        
        groupings.forEach { label, points in
            let values = points.map { $0.index }
            
            if label == nil {
                outliers.append(contentsOf: values)
            } else {
                clusters.append(values)
            }
        }
        
        return (clusters, outliers)
    }
    
    /// Tunes the hyperparameters of the DBScan algorithm on the provided corpus and returns the clusters and outliers.
    /// - Parameters:
    ///   - corpus: The corpus to cluster.
    ///   - epsRange: The range of epsilon values to consider.
    ///   - minNeighboursRange: The range of minimum number of neighbours to consider.
    /// - Returns: The clusters and outliers
//    mutating func getClustersWithTuning<C: SNLPIndexedCorpus>(_ corpus: C, epsRange: [C.Encoder.Scalar], minNeighboursRange: [Int], showProgress: Bool = false, showOtherCandidates: Bool = false) async -> (clusters: [[Int]], outliers: [Int]?) {
//        let (eps, minNeighbours) = await DBScan.tune(on: corpus, epsRange: epsRange, minNeighboursRange: minNeighboursRange, showProgress: showProgress)
//        
//        if showProgress {
//            print("Using Best eps: \(eps), Best minNeighbours: \(minNeighbours)")
//        }
//        
//        self.eps = Double(eps)
//        self.minNeighbours = minNeighbours
//        
//        return await self.getClusters(corpus)
//    }
}

//extension DBScan {
//    // TODO: Make this a requirement of the protocol (might be challenging or impossible because they all have different number and types of hyperparameters...)
//    // IDEA: have an 'autotune' parameter that will automatically tune the hyperparameters and predict suitable epsRange and minNeighboursRange
////    static func tune<C: SNLPIndexedCorpus>(on corpus: C, epsRange: [C.Encoder.Scalar], minNeighboursRange: [Int], showProgress: Bool = false, showOtherCandidates: Bool = false) async -> (eps: C.Encoder.Scalar, minNeighbours: Int) {
////        let totalSize = epsRange.count * minNeighboursRange.count
////        
////        var bestScore = 0.0
////        var bestEps: C.Encoder.Scalar = C.Encoder.Scalar.leastNormalMagnitude
////        var bestMinNeighbours: Int = 0
////        var otherCandidates: [(eps: C.Encoder.Scalar, minNeighbours: Int, score: Double)] = []
////        
////        for (i, eps) in epsRange.enumerated() {
////            for (j, minNeighbours) in minNeighboursRange.enumerated() {
////                var topicModel = BasicTopicModel(
////                    corpus: corpus,
////                    clusteringAlgorithm: DBScan(
////                        eps: Double(eps),
////                        minNeighbours: minNeighbours
////                    )
////                )
////                
////                await topicModel.cluster()
////                await topicModel.generateKeywords()
////                
////                // TODO: Make this flexible
////                let score = topicModel.topicDiversity(topK: 10)
////                
////                if showProgress {
////                    let progress = Double(i * minNeighboursRange.count + j) / Double(totalSize) * 100.0
////                    print("Eps: \(eps), Min Neighbours: \(minNeighbours)")
////                    print("Topic diversity: \(score)")
////                    print("Progress: \(progress)%")
////                }
////                
////                // TODO: This score is also dependent on the metric... might be useful to define what is a good 'range' for a specific score
////                if 0.1 <= score, score <= 0.9 {
////                    otherCandidates.append((eps: eps, minNeighbours: minNeighbours, score: score))
////                }
////                
////                // Only consider scores between 0.1 and 0.9 (ignores extreme values)
////                if score > bestScore, 0.1 <= score, score <= 0.9 {
////                    bestScore = score
////                    bestEps = eps
////                    bestMinNeighbours = minNeighbours
////                }
////            }
////        }
////        
////        if showOtherCandidates {
////            print("Other candidates:")
////            for candidate in otherCandidates {
////                print("Eps: \(candidate.eps), Min Neighbours: \(candidate.minNeighbours) (Score: \(candidate.score))")
////            }
////        }
////        
////        return (eps: bestEps, minNeighbours: bestMinNeighbours)
////    }
//    
//    static func tune<C: SNLPIndexedCorpus>(
//        on corpus: C,
//        epsRange: [C.Encoder.Scalar],
//        minNeighboursRange: [Int],
//        showProgress: Bool = false,
//        showOtherCandidates: Bool = false
//    ) async -> (eps: C.Encoder.Scalar, minNeighbours: Int) {
//        
//        let totalSize = epsRange.count * minNeighboursRange.count
//        
//        var bestScore = 0.0
//        var bestEps: C.Encoder.Scalar = C.Encoder.Scalar.leastNormalMagnitude
//        var bestMinNeighbours: Int = 0
//        var otherCandidates: [(eps: C.Encoder.Scalar, minNeighbours: Int, score: Double)] = []
//        
//        // Create a task group to run combinations concurrently
//        await withTaskGroup(of: (C.Encoder.Scalar, Int, Double).self) { group in
//            for eps in epsRange {
//                for minNeighbours in minNeighboursRange {
//                    group.addTask { [corpus = corpus, eps = eps] in
//                        var topicModel = BasicTopicModel(
//                            corpus: corpus,
//                            clusteringAlgorithm: DBScan(
//                                eps: Double(eps),
//                                minNeighbours: minNeighbours
//                            )
//                        )
//                        
//                        await topicModel.cluster()
//                        await topicModel.generateKeywords()
//                        
//                        let score = topicModel.topicDiversity(topK: 10)
//                        return (eps, minNeighbours, score)
//                    }
//                }
//            }
//            
//            // Track the number of completed tasks
//            var completedTasks = 0
//            
//            // Collect results from tasks
//            for await (eps, minNeighbours, score) in group {
//                completedTasks += 1
//                
//                if showProgress {
//                    let progress = Double(completedTasks) / Double(totalSize) * 100.0
//                    print("Eps: \(eps), Min Neighbours: \(minNeighbours)")
//                    print("Topic diversity: \(score)")
//                    print("Progress: \(progress)%")
//                }
//                
//                if 0.1 <= score, score <= 0.9 {
//                    otherCandidates.append((eps: eps, minNeighbours: minNeighbours, score: score))
//                }
//                
//                if score > bestScore, 0.1 <= score, score <= 0.9 {
//                    bestScore = score
//                    bestEps = eps
//                    bestMinNeighbours = minNeighbours
//                }
//            }
//        }
//        
//        if showOtherCandidates {
//            print("Other candidates:")
//            for candidate in otherCandidates {
//                print("Eps: \(candidate.eps), Min Neighbours: \(candidate.minNeighbours) (Score: \(candidate.score))")
//            }
//        }
//        
//        return (eps: bestEps, minNeighbours: bestMinNeighbours)
//    }
//
//}
