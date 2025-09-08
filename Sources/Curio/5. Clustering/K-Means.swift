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
import Accelerate
@preconcurrency import MLX
import MLXLinalg

/// A structure representing the KMeans clustering algorithm.
///
/// This implementation uses efficient matrix operations for performance
/// and supports k-means++ initialization for better initial centroids.
struct KMeans: SNLPClusteringAlgorithm {
    
    /// The number of centers (clusters) for the KMeans algorithm.
    let numCenters: Int

    /// The distance metric we're using to identify clusters
    //internal var metric: any DistanceMetric
    
    /// The centroids of the clusters, updated during training.
    private(set) var centroids = MLXArray()
    
    /// The convergence distance to determine when the centroids have stabilized.
    private var convergeDistance: Float

    /// Initializes a new instance of the KMeans clustering algorithm.
    /// - Parameters:
    ///   - numTopics: The number of clusters to find.
    ///   - convergeDistance: The distance threshold for convergence. Default is 0.01.
    init(numTopics: Int, convergeDistance: Float = 0.01) { // Increased convergeDistance for faster convergence
        assert(numTopics > 1, "Exception: KMeans with less than 2 centers.")
        self.numCenters = numTopics
        self.convergeDistance = convergeDistance
    }

    /// Gets the clusters for the given data points.
    /// - Parameter data: The data points to be clustered, represented as an MLXArray.
    /// - Returns: A tuple containing the clusters and optional outliers.
    mutating func getClusters(_ data: MLX.MLXArray, metric: DistanceMetric) async -> (clusters: [[Int]], outliers: [Int]?) {
        trainCenters(points: data, metric: metric)
        let labels = fit(points: data, metric: metric)
        
        // Group points by labels using a dictionary
        var labelGroups: [Int: [Int]] = [:]
        for (index, label) in labels.enumerated() {
            labelGroups[label, default: []].append(index)
        }
        
        let clusters = Array(labelGroups.values)
        return (clusters, nil)
    }
    
    /// Gets the clusters for the given corpus.
    /// - Parameter corpus: The indexed corpus to be clustered.
    /// - Returns: A tuple containing the clusters and optional outliers.
    mutating func getClusters<C>(_ corpus: C) async -> (clusters: [[Int]], outliers: [Int]?) where C : SNLPCorpus {
        return await getClusters(corpus.encodedDocumentsAsMLXArray, metric: corpus.metric)
    }
    
    /// Initializes the centroids using k-means++ initialization.
    /// - Parameter points: The data points to initialize the centroids from.
    internal mutating func initializeCenters(points: MLXArray, metric: DistanceMetric) {
        // Randomly select the first centroid from the data points
        let firstIndex = Int.random(in: 0..<points.shape[0])
        let centers = MLXArray.zeros([numCenters, points.shape[1]])
        centers[0] = points[firstIndex]
        
        // Initialize the remaining centroids using the stored distance metric.
        for i in 1..<numCenters {
            // Use only the current centers for distance computation.
            let currentCenters = centers[0..<i]
            // Compute the distance matrix between all points and the current centers.
            let distancesMatrix = metric.fullPairwiseDistance(between: points, currentCenters)
            // For each point, get the minimum distance to any center.
            let minDistances: MLXArray = distancesMatrix.shape.count == 1
                        ? distancesMatrix
                        : distancesMatrix.min(axis: 1)
            
            // Ensure the sum of distances is positive.
            let minDistancesSum = minDistances.sum()
            guard minDistancesSum.item() > 0 else { continue }
            
            // Select the next centroid with probability proportional to its distance.
            let probabilities = minDistances / minDistancesSum
            let cumulativeProbabilities = probabilities.cumsum()
            cumulativeProbabilities[cumulativeProbabilities.shape[0] - 1] = MLXArray(1.0)
            
            let randomValue = Float.random(in: 0..<1) * (1.0 - .ulpOfOne)
            guard let nextIndex = cumulativeProbabilities.asArray(Float.self)
                    .firstIndex(where: { $0 >= randomValue })
            else {
                fatalError("No valid index found for random value \(randomValue).")
            }
            
            centers[i] = points[nextIndex]
        }
        
        centroids = centers
    }


    
    /// Trains the centroids using the given data points.
    /// - Parameter points: The data points to train the centroids on.
    internal mutating func trainCenters(points: MLXArray, metric: DistanceMetric) {
        // Initialize centroids using k-means++
        initializeCenters(points: points, metric: metric)
        
        var centerMoveDist = Float.infinity
        let maxIterations = 100
        var iterations = 0
        
        let numPoints = points.shape[0]
        let numFeatures = points.shape[1]
        
        while centerMoveDist > convergeDistance && iterations < maxIterations {
            iterations += 1
                      
            // Calculate the distance matrix using broadcasting
            let distances = metric.fullPairwiseDistance(between: points, centroids)
            let labels = argMin(distances, axis: 1)
            
            // Calculate new centroids using matrix math
            let newCenters = MLXArray.zeros([numCenters, numFeatures])
            let labelCounts = MLXArray.zeros([numCenters])
            
            for i in 0 ..< numPoints {
                let label = labels[i]
                newCenters[label] += points[i]
                labelCounts[label] += 1
            }

            // Average the summed points for each cluster to update centroids
            for i in 0 ..< numCenters {
                if labelCounts[i].item() > 0 {
                    newCenters[i] /= labelCounts[i]
                } else {
                    newCenters[i] = centroids[i] // If no points in cluster, retain old centroid
                }
            }
            
            // Calculate movement distance
            centerMoveDist = norm(newCenters - centroids, stream: .gpu).item()
            
            // Update centers
            centroids = newCenters
        }
    }
    
    /// Assigns each point to the nearest centroid.
    /// - Parameter points: The data points to be assigned to clusters.
    /// - Returns: An array of cluster labels for each point.
    func fit(points: MLXArray, metric: DistanceMetric) -> [Int] {

        // Efficient pairwise distance calculation using matrix operations
        let distances = metric.fullPairwiseDistance(between: points, centroids)
        
        // Calculate the distance matrix
        let labels = argMin(distances, axis: 1)
        
        assert(labels.count == points.shape[0])
        
        return labels.asArray(Int.self)
    }
}
