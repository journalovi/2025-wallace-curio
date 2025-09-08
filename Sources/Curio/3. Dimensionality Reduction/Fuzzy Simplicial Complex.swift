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
@preconcurrency import MLX

public struct FuzzySimplicialComplex: Sendable, CustomStringConvertible {

    public let k: Int
    public let neighbours: [[FSCEdge]]
    
    //internal var labels: [String] = [String]()
    
    init( neighbours: [[FSCEdge]], k: Int) {
        self.neighbours = neighbours
        self.k = k
    }
    
    init(_ corpus: any SNLPIndexedCorpus, k: Int) async {
        await self.init(corpus.encodedDocumentsAsMLXArray, index: corpus.index, k: k)
    }
    
    init(_ corpus: MLXArray, index: any SNLPIndex, k: Int) async {
        let availableProcessors = max(ProcessInfo.processInfo.processorCount - 2, 1)
        let batchSize = max(corpus.shape[0] / availableProcessors, 1)
        let totalNodes = corpus.shape[0]
        var neighboursArray: [[FSCEdge]] = Array(repeating: [], count: totalNodes)

        corpus.eval()
        
        //print("Building FSC with \(index)")
        
        await withTaskGroup(of: (Range<Int>, [[FSCEdge]]).self) { taskGroup in
            for batchStart in stride(from: 0, to: totalNodes, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, totalNodes)
                let batchRange = batchStart..<batchEnd

                // FAISS isn't thread-safe, so clone the index for this part
                guard let index = index as? FAISS else {
                    fatalError("HNSW index is not yet supported for UMAP")
                }
                let indexCopy = await index.clone()

                
                taskGroup.addTask {
                    var batchEdges: [[FSCEdge]] = []

                    for node in batchRange {
                        // Fetch neighbors for the node
                        var nodeNeighbours = [Int]()
                        var searchRange = k + 1
                        while nodeNeighbours.count < k && searchRange < corpus.shape[0] {
                            nodeNeighbours = indexCopy.find(near: corpus[node], limit: searchRange).filter { $0 != node }.suffix(k)
                            searchRange *= 2
                            if nodeNeighbours.count < k {
                                print("Index Miss: \(node) -> \(nodeNeighbours.count)")
                            }
                        }

                        assert( nodeNeighbours.count == k )
                        
                        // Calculate distances and determine sigma and rho
                        var distances = [Double]()
                        for neighbour in nodeNeighbours {
                            let distance: Double = index.metric.distance(between: corpus[node], corpus[neighbour])
                            distances.append(distance)
                        }

                        // Sort distances to determine sigma and rho
                        //let sortedDistances = distances.sorted()
                        let rho = distances.filter{ $0 > 0 }.min() ?? 0.0
                        let sigma = FuzzySimplicialComplex.computeSigma(distances: distances, k: k, rho: rho)
                        

                        // Create edges with the calculated weight
                        var edgeArray = [FSCEdge]()
                        for (index, neighbour) in nodeNeighbours.enumerated() {
                            
                            assert( node >= 0 && node < totalNodes)
                            assert( neighbour >= 0 && neighbour < totalNodes)
                            
                            let weight = Foundation.exp(-max(0.0, distances[index] - rho) / sigma)
                            let newEdge = FSCEdge(a: node, b: neighbour, distance: Float(distances[index]), weight: Float(weight))
                            edgeArray.append(newEdge)
                        }

//                        print("SIGMA: \(sigma) RHO: \(rho)")
//                        var output = ""
//                        for e in edgeArray {
//                            if let labels {
//                                output += "|\(labels[e.a]) \(e.a) -> \(e.b) : d\(e.distance) : w\(e.weight)|"
//                            }
//                        }
//                        print(output)
                        assert(edgeArray.count == k)
                        batchEdges.append(edgeArray)
                    }

                    // Return the range and corresponding edges for the batch
                    return (batchRange, batchEdges)
                }
            }

            // Process results as soon as each batch is available
            for await (batchRange, batchEdges) in taskGroup {
                for (i, node) in batchRange.enumerated() {
                    neighboursArray[node] = batchEdges[i]
                }
            }
        }

        self.neighbours = neighboursArray
        self.k = k

        assert(self.neighbours.count == totalNodes)
    }



    
    func isNeighbor(_ i: Int, _ j: Int) -> Bool {
        return neighbours[i].contains(where: { $0.b == j })
    }
    
    static func computeSigma(distances: [Double], k: Int, rho: Double) -> Double {
        guard k > 0, !distances.isEmpty else {
            return 1.0 // Default fallback
        }
        
        let logK = log(Double(k)) // Natural logarithm of k
        let targetSum = logK
        
        // Binary search for sigma
        var low: Double = 1e-5
        var high: Double = 100.0
        let tolerance: Double = 1e-5
        
        while high - low > tolerance {
            let mid = (low + high) / 2.0
            let sum = distances[0..<min(k, distances.count)].reduce(0.0) { partialSum, d in
                partialSum + exp(-(d - rho) / mid)
            }
            
            if sum < targetSum {
                high = mid
            } else {
                low = mid
            }
        }
        
        return (low + high) / 2.0
    }
    
    public var description: String {
        var result = "Full Neighbour List:\n"
        for (node, edges) in neighbours.enumerated() {
            result += "Node \(node):\n"
            for edge in edges {
                result += "  -> Neighbour: \(edge.b), Distance: \(edge.distance), Weight: \(edge.weight)\n"
            }
        }
        return result
    }
}

