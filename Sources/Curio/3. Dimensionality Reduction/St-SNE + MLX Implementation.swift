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
import Cmlx
@preconcurrency import MLX
import MLXLinalg
import MLXNN
import Synchronization

extension StSNE {
        
    // Step 1: Compute Pairwise Affinities in High-Dimensional Space (assuming normalized embeddings)
        @inlinable
        internal static func computeHighDimAffinities(
            data: MLXArray,
            mask: MLXArray
        ) -> MLXArray {
            // Step 1: Calculate pairwise cosine dis-similarities
            // Since embeddings are normalized, dot product directly gives cosine similarity
            let cosineSimilarity = 1 - data.matmul(data.T, stream: .gpu)

            // Convert cosine similarities to affinities (by shifting from [-1, 1] to [0, 1] range)
            let affinities = (cosineSimilarity + 1.0) / 2.0
            
            // Step 2: Prepare the affinities matrix
            //let nPoints = affinities.shape[0]
            affinities *= mask

            // Normalize rows (optional but common in similarity-based affinity matrices)
            let rowSum = affinities.sum(axis: 1, keepDims: true)
            var normalizedAffinities = affinities / rowSum
            
            // Set diagonal to 0 to exclude self-similarity
            //let indices = MLXArray(0 ..< nPoints)
            //normalizedAffinities[indices, indices] = MLXArray(0)
            
            // Step 3: Symmetrize affinities
            normalizedAffinities = (normalizedAffinities + normalizedAffinities.T) / 2.0

            // Step 4: Normalize entire affinities matrix to sum to 1
            let totalSum = normalizedAffinities.sum()
            normalizedAffinities /= totalSum
            
            return normalizedAffinities
        }

        // Step 3: Compute Pairwise Affinities in Low-Dimensional Space using Cosine Similarity
        @inlinable
        internal static func computeLowDimAffinities(_ Y: MLXArray) -> MLXArray {
            
            // 1. Compute pairwise cosine similarities
            let cosineSimilarity = Y.matmul(Y.T, stream: .gpu)
            let affinities = (cosineSimilarity + 1.0) / 2.0  // Convert to [0, 1] range
            
            // 2. Set diagonal to 0 (ignore self-similarities)
            let indices = MLXArray(0 ..< Y.shape[0])
            affinities[indices, indices] = MLXArray(0)
            
            // 3. Normalize to form a probability matrix Q
            let Q_sum = affinities.sum()  // Sum of all elements in Q
            let Q_normalized = affinities / Q_sum  // Element-wise division

            return Q_normalized
        }
    
            

    @inlinable
    internal static func loss(arrays: [MLXArray]) -> [MLXArray] {
        // Arrays: [ldBatch, hdAffinities]
        let ldAffinities = StSNE.computeLowDimAffinities(arrays[0])
        let hdAffinities = arrays[1]

        let epsilon = 1e-10  // Small value to ensure numerical stability

        // Attractive component: P * log(P / Q)
        let attractiveLoss = (hdAffinities * log((hdAffinities + epsilon) / (ldAffinities + epsilon))).sum()

        // Repulsive component: (1 - P) * log(1 - Q)
        let one = MLXArray.ones(ldAffinities.shape)
        let repulsiveLoss = ((one - hdAffinities) * log((one + epsilon) - ldAffinities)).sum()

        // Total loss is the sum of both components
        let totalLoss = attractiveLoss + repulsiveLoss

        return [totalLoss]
    }

    
    
    // Step 4: Compute Gradient and Update Y via Stochastic Gradient Descent
    // TODO: Other librariries use a much higher learning rate, e.g., auto = max(N / early_exaggeration / 4, 50)
    internal func gradientDescent() async
    {
        
        // TODO: Keep batch sizes consistent
        // TODO: Learning rate proportional to size of batch / size of data set
        
        
        let bestLoss = Mutex<Float>(.greatestFiniteMagnitude)
        var earlyStopCounter = 0
        let totalSize = ldEmbeddingsMutex.withLock{ ld in ld.shape[0] }
        let batchSize = self.batchSize < totalSize ? self.batchSize : totalSize // We can only make batches so big
        let earlyExaggeration = self.earlyExaggeration * ( Float(batchSize) / Float(totalSize) )
        let breakIn = Int(Float(self.breakIn) * ( Float(batchSize) / Float(totalSize) ))
        let adjustedLearningRate = learningRate * ( Float(batchSize) / Float(totalSize) )
                
        await withTaskGroup(of: (Float,Float).self) { group in
            
            var numActiveThreads = 0
            var completed = 0
            computeValueAndGradient = valueAndGrad(tSNE.loss)
            /// Create a separate batch for each thread we want to process concurrently
            /// - Create a set of indices randomly that we plan on using for our calculations
            /// - Create working copies of low- and high-dimensional embedddings
            /// - Then, each thread will:
            ///     - Calculate high-dimensional affinities
            ///     - Calculate gradient
            ///     - return value and gradient norm so we can decide if we want to quit early
            for i in 0 ..< maxIterations {
                guard let kNNIndex else { return }
                while numActiveThreads < numThreads {
                    group.addTask(priority: .high) { [unowned self] in
                        
                        // Randomly shuffle indices to select a batch
                        var neighbors = Set<Int>()
                        var kNNResults = [Int: [Int]]() // Cache kNN results
                        
                        // Make sure batchSize is consistent
                        while neighbors.count < batchSize {
                            
                            let nextIndex = Int.random(in: 0 ..< totalSize)
                            
                            // Perform kNN search to find perplexity * 3 additional indices
                            let result = await kNNIndex.find(near: self.hdEmbeddings[nextIndex], limit: Int(perplexity)*3).filter { $0 != -1 }
                            neighbors.formUnion(result)
                            kNNResults[nextIndex] = result // Cache the results
                        }
                        // Trim any extras
                        while neighbors.count > batchSize { neighbors.removeFirst() }
                        
                        // Make a new array with unique indices as the first elements, and neighbors as the last ones
                        let indices = Array(neighbors)
                        
                        // Construct an adjacency matrix for the selected neighbors
                        let neighborList = Array(neighbors)
                        let n = neighborList.count
                        var adjacencyMatrix = [[Float]](repeating: [Float](repeating: 0, count: n), count: n)

                        for (i, nodeA) in neighborList.enumerated() {
                            // Retrieve precomputed k-nearest neighbors for nodeA
                            guard let kNearestNeighbors = kNNResults[nodeA] else { continue }
                            
                            for (j, nodeB) in neighborList.enumerated() {
                                if i != j {
                                    // If nodeB is a k nearest neighbor of nodeA, set adjacencyMatrix[i][j] to 1
                                    if kNearestNeighbors.contains(nodeB) {
                                        adjacencyMatrix[i][j] = 1
                                    }
                                }
                            }
                        }
                        
                        
                        let hdBatch = self.hdEmbeddings[ MLXArray(indices) ]
                        let kNNmask = MLXArray(adjacencyMatrix.flatMap{ $0 }, [n,n] )
                        let hdAffinities = StSNE.computeHighDimAffinities(data: hdBatch, mask: kNNmask)
                        if i < breakIn {
                            hdAffinities *= earlyExaggeration
                        }
                                                
                        // Create mini-batch for ldEmbeddings based on selected indices
                        let ldBatch = self.ldEmbeddingsMutex.withLock { ld in return ld[MLXArray(indices)] }
                        
                        // Compute the gradient for the current batch
                        let (value, gradient) = computeValueAndGradient([ldBatch, hdAffinities])
                        
                        // Update our ldEmbeddings estimate for the next batch
                        // Make sure we don't do this at the same time as another worker task
                        self.ldEmbeddingsMutex.withLock { ld in
                            for (_, idx) in indices.enumerated() {
                                ld[idx] -= adjustedLearningRate * gradient[0]
                            }
                            ld.eval()
                        }
                        
                        return (value[0].item(), norm(gradient[0]).item())
                    }
                    
                    numActiveThreads += 1
                    //print("New thread added: \(numActiveThreads)/\(numThreads) threads active")
                }
                
                // Wait until we have room for additional Tasks
                if let (value, gradientNorm) = await group.next() {
                    numActiveThreads -= 1
                    completed += 1
                    //klDivergence = value
                    if i % 50 == 0 {
                        print("\(i): KL Divergence: \(value)")
                    }
                    
                    //print("Loss: \(value)")
                    
                    //If our gradient norm is too small, stop
                    if gradientNorm < minimumGradientNorm {
                        print("Norm too small: \(completed)")
                        break
                    }
                    
                    //If we're far enough into this process, monitor for whether we can early exit
                    if completed > breakIn {
                        
                        // Evaluate the loss value
                        bestLoss.withLock { bestLoss in
                            if value < bestLoss {
                                bestLoss = value
                                earlyStopCounter = 0
                            } else {
                                earlyStopCounter += 1
                            }
                        }
                        if earlyStopCounter >= patience {
                            print("Early stop: \(completed)")
                            break
                        }
                    }
                }
            }
        }
    }
}

