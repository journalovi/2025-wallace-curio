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
@preconcurrency import Cmlx
@preconcurrency import MLX
@preconcurrency import MLXLinalg
@preconcurrency import MLXNN
import Synchronization

extension tSNE {
        
    @inlinable
    internal static func computeHighDimAffinities(data: MLXArray, mask: MLXArray) -> MLXArray {

        // Step 1: Calculate pairwise Euclidean distances
        let dataSqSums = data.square().sum(axis: 1, keepDims: true)
        let distances = clip(dataSqSums + dataSqSums.T - 2 * data.matmul(data.T, stream: .gpu), min: 0.0)

        // Precompute standard deviations for Gaussian kernel
        let stdDevs = 2 * pow(std(distances, axis: 1, keepDims: true, stream: .gpu) + 1e-8, 2) // Add epsilon to avoid zero std deviation

        // Compute Gaussian affinities for all pairs
        var affinities = exp(-distances / stdDevs)

        // Apply mask to restrict affinities to specific pairs (symmetric application)
        affinities *= mask

        // Ensure no NaN values after masking
        //affinities = nanToNum(affinities)

        // Ensure symmetry after applying the mask
        //affinities = (affinities + affinities.T) / 2.0

        // Step 3: Normalize rows to ensure they sum to 1
        let rowSum = affinities.sum(axis: 1, keepDims: true) + 1e-8 // Add epsilon to prevent division by zero
        affinities = affinities / rowSum

        // Step 4: Normalize entire affinities matrix to sum to 1
        let totalSum = affinities.sum() + 1e-8 // Add epsilon to prevent division by zero
        affinities /= totalSum

        return affinities
    }


    
    // Step 3: Compute Pairwise Affinities in Low-Dimensional Space
    @inlinable
    internal static func computeLowDimAffinities(_ Y: MLXArray) -> MLXArray {
        // 1. Compute squared norms of each row in Y
        //let y2 = Y * Y
        let sum_Y = Y.square().sum(axis: 1, keepDims: true)  // (N,)
        
        // 2. Compute pairwise squared distances
        let distances_sq = sum_Y.reshaped([-1,1]) + sum_Y.reshaped([1,-1]) - 2 * (Y.matmul(Y.transposed(), stream: .gpu))
        
        // 3. Apply the Student-t kernel element-wise: Q = 1 / (1 + distances_sq)
        let oneTensor = MLXArray(1.0)
        var Q = oneTensor / (oneTensor + distances_sq)
        
        // 4. Set diagonal to 0 (ignore self-similarities)
        // TODO: Figure out the MLX way to do this
        let qNeg = Q.diag() * -1
        Q = Q + qNeg
        
        // 5. Normalize to form a probability matrix Q
        let Q_sum = Q.sum()  // Sum of all elements in Q
        let Q_normalized = Q / Q_sum  // Element-wise division

        return Q_normalized
    }
    
            

//    @inlinable
//    internal static func loss(arrays: [MLXArray]) -> [MLXArray] {
//        return [klDivLoss(inputs: arrays[1] + 1e-10, targets: computeLowDimAffinities(arrays[0]), reduction: .sum)]
//    }
        
    @inlinable
    internal static func loss(arrays: [MLXArray]) -> [MLXArray] {
        // Arrays: [ldBatch, hdAffinities]
        let ldAffinities = computeLowDimAffinities(arrays[0])
        let hdAffinities = arrays[1]

        let epsilon = 1e-8  // Small value to ensure numerical stability

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
        let adjustedLearningRate = learningRate * ( Float(batchSize) / Float(totalSize) )
        //let breakIn = self.breakIn * Int( Float(totalSize) / Float(batchSize) )
                        
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
                        //var localExaggeration = Double(self.earlyExaggeration)
                        let decrement: Double = (Double(earlyExaggeration) - 1.0) / Double(breakIn)

                        var neighbors = Set<Int>()
                        var kNNResults = [Int: [Int]]() // Cache kNN results
                        let localIndex = await kNNIndex.clone()
                        
                        // Make sure batchSize is consistent
                        while neighbors.count < batchSize {
                            
                            let nextIndex = Int.random(in: 0 ..< totalSize)
                            
                            // Perform kNN search to find perplexity * 3 additional indices
                            //let indexCount = localIndex.index.count
                            //_ = nanToNum(self.hdEmbeddings[nextIndex]).asArray(Float.self)
                            let result = await localIndex.find(near: nanToNum(self.hdEmbeddings[nextIndex]), limit: Int(perplexity)*3)
                            
                            neighbors.formUnion(result)
                            kNNResults[nextIndex] = result // Cache the results
                            
                            assert( kNNResults.count != totalSize ) // If we've looked at every point, something is very wrong
                        }
                        // Trim any extras
                        while neighbors.count > batchSize { neighbors.removeFirst() }
                        
                        // Make a new array with unique indices as the first elements, and neighbors as the last ones
                        let indices = Array(neighbors)
                        
                        // Construct an adjacency matrix for the selected neighbors
                        let neighborList = Array(neighbors)
                        let n = neighborList.count
                        var adjacencyMatrix = [[Float]](repeating: [Float](repeating: 0.01, count: n), count: n)

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
                        let hdAffinities = tSNE.computeHighDimAffinities(data: hdBatch, mask: kNNmask)
                        
                        // Ease off early exaggeration instead of just cutting it off
                        if i < breakIn {
                            var localExaggeration = Double(earlyExaggeration) - decrement * Double(i)
                            localExaggeration = max(localExaggeration, 1.0)
                            hdAffinities *= localExaggeration
                            //print("\(i): localExageration: \(localExaggeration)  Decrement: \(decrement)")
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
                    klDivergence = value
                    if i % 50 == 0 {
                        print("\(i): KL Divergence: \(value)")
                    }
                    
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
                            //print("Early stop: \(completed)")
                            break
                        }
                    }
                }
            }
        }
    }
}
