import MLX
import MLXOptimizers
import MLXRandom
import MLXNN
import MLXLinalg

/// UMAP Module that learns a low-dimensional embedding of data.
class UMAPModule: Module {
    
    // Trainable embedding matrix (shape: [n_samples, n_components])
    var embedding: MLXArray
    let distanceMetric: DistanceMetric

    
    let epsilon: Float = 1e-6  // Small constant for numerical stability.
    
    // Fuzzy neighbor graph (high-dimensional relationships)
    let fuzzyComplex: FuzzySimplicialComplex
    let numNeighbours: Int
    let negativeSampleRate: Int
    let corpus: any SNLPIndexedCorpus
    
    // UMAP hyperparameters
    let a: MLXArray
    let b: MLXArray

    // Internal variables for computations
    let attract_i: MLXArray
    let attract_j: MLXArray
    let attract_w: MLXArray
    
    init<C: SNLPIndexedCorpus>(
        _ corpus: inout C,
        targetDimensions: Int,
        numNeighbours: Int,
        negativeSampleRate: Int = 5,
        initialValues: InitialValues = .random,
        distanceMetric: DistanceMetric = CosineSimilarity(),
        a: Float = 1.577,
        b: Float = 0.895
    ) async {
                
        // 0. Generate an FSC for this corpus in high-dimensional space
        fuzzyComplex = await FuzzySimplicialComplex(corpus, k: numNeighbours)
        self.numNeighbours = numNeighbours
        self.negativeSampleRate = negativeSampleRate
        self.corpus = corpus
        self.distanceMetric = distanceMetric
        self.a = MLXArray(a)
        self.b = MLXArray(b)
        
        // 1. Initialize embedding with small random values.
        switch initialValues {
        case .laplacian:
            let laplacian = LaplacianReducer(targetDimensions: targetDimensions, fsc: fuzzyComplex)
            laplacian.reduce(&corpus.encodedDocumentsAsMLXArray)
            embedding = corpus.encodedDocumentsAsMLXArray
            
        case .pca:
            let pca = PCA(targetDimensions: targetDimensions)
            pca.reduce(&corpus.encodedDocumentsAsMLXArray)
            embedding = corpus.encodedDocumentsAsMLXArray
            
        case .random:
            embedding = MLXRandom.normal([corpus.count, targetDimensions], dtype: .bfloat16)
        }
        
        
        // 2. Convert neighbor pairs to MLXArrays.
        var neighborPairs: [(Int, Int, Float)] = []
        for edges in fuzzyComplex.neighbours {
            for edge in edges {
                neighborPairs.append((edge.a, edge.b, edge.weight))
            }
        }
        attract_i = neighborPairs.map { Int32($0.0) }.asMLXArray(dtype: .int32)
        attract_j = neighborPairs.map { Int32($0.1) }.asMLXArray(dtype: .int32)
        attract_w = neighborPairs.map { $0.2 }.asMLXArray(dtype: .float32)
        
        assert( !attract_i.asArray(Float.self).contains(where: { $0.isNaN }) )
        assert( !attract_j.asArray(Float.self).contains(where: { $0.isNaN }) )
        assert( !attract_w.asArray(Float.self).contains(where: { $0.isNaN }) )
        
        // Initialize base Module (registers parameters)
        super.init()
    }
}

extension UMAPModule {

    /// Compute the UMAP cross-entropy loss for the current embedding.
    /// - Returns: A scalar MLXArray representing the loss value.
    func attractiveLoss(_ input: [MLXArray]) -> [MLXArray] {
        assert(input.count == 1, "Expected a single MLXArray input.")
        
        let input = input[0]
        let pos_i = input[attract_i]  // shape: [numAttract, nDims]
        let pos_j = input[attract_j]  // shape: [numAttract, nDims]
        
        // Compute squared distances using the generic batchDistance function.
        let distSq = distanceMetric.batchDistance(between: pos_i, pos_j).square()
        
        // Compute abTerm = a * (distance^2)^b.
        let abTerm = a * distSq.pow(b)
        let one = MLXArray(1.0)
        
        // Compute q_ij = 1 / (1 + a * (distance^2)^b)
        let q_ij = one / (one + abTerm)
        
        // Log q_ij statistics for debugging.
        //let qStats = q_ij.asArray(Float.self)
        //if let minQ = qStats.min(), let maxQ = qStats.max() {
        //    let meanQ = qStats.reduce(0, +) / Float(qStats.count)
            //print("q_ij stats - min: \(minQ), max: \(maxQ), mean: \(meanQ)")
        //}
        
        // Use a larger epsilon for stability (adjust if necessary)
        let stableEpsilon: Float = 1e-3
        let safe_q_ij = clip(q_ij, min: stableEpsilon, max: 1.0 - stableEpsilon)
        
        
        // Compute the log.
        let log_q = safe_q_ij.log()
        
        // Compute the attractive loss.
        let attractLoss = -(log_q * attract_w).sum()
        //print("Attractive loss: \(attractLoss.item(Float.self))")
        
        return [attractLoss]
    }

        
        
        /// Compute the UMAP cross-entropy loss for the current embedding.
        /// - Returns: A scalar MLXArray representing the loss value.
    func repulsiveLoss(_ input: [MLXArray]) -> [MLXArray] {
        
        assert( input.count == 1 )
        
        // Generate negative samples
        var negativeSamples: [(Int, Int)] = []
        
        for idx in 0 ..< numNeighbours {
            var sampledPoints = Set<Int>()
            while sampledPoints.count < negativeSampleRate {
                let j = Int.random(in: 0 ..< corpus.count)
                if j != idx && !fuzzyComplex.isNeighbor(idx, j) && !fuzzyComplex.isNeighbor(j, idx) {
                    sampledPoints.insert(j)
                }
            }
            negativeSamples.append(contentsOf: sampledPoints.map{ (idx, $0) })
        }
        let repel_i = negativeSamples.map { Int32($0.0) }.asMLXArray(dtype: .int32)
        let repel_j = negativeSamples.map { Int32($0.1) }.asMLXArray(dtype: .int32)

        
        let input = input[0]
        let pos_iNeg = input[repel_i] // [numNeg, nDims]
        let pos_kNeg = input[repel_j] // [numNeg, nDims]
        
        // Compute squared distances for repulsion.
        let distSqNeg = distanceMetric.batchDistance(between: pos_iNeg, pos_kNeg).square()
        
        // UMAP formulation for repulsion: q_ik = 1 / (1 + a * (distSqNeg)^b)
        let q_ik = 1.0 / (1.0 + a * distSqNeg.pow(b))
        let safeOneMinusQik = clip( (1.0 - q_ik), min: epsilon, max: 1.0 - epsilon)
        let repelLoss = -safeOneMinusQik.log().sum()
        
        return [repelLoss]
    }

    
    
    /// Optimize the embedding using a given MLX optimizer for a number of epochs.
    func optimizeEmbedding<Opt: OptimizerBase<MLXArray>>(optimizer: Opt, epochs: Int, tolerance: Float = 1e-4) {
        var state = optimizer.newState(parameter: embedding)
        let attractiveLG = valueAndGrad(attractiveLoss)
        let repusliveLG = valueAndGrad(repulsiveLoss)
        var previousLoss: Float = 0.0
        
        for epoch in 1 ..< epochs {
            
            let (av, ag) = attractiveLG([self.embedding])
            let (rv, rg) = repusliveLG([self.embedding])
            
            let currentLoss = av[0].item(Float.self) + rv[0].item(Float.self)
            let deltaLoss = abs(currentLoss - previousLoss)
            if deltaLoss < tolerance {
                break
            }
            previousLoss = currentLoss
            
            // Original UMAP implementation - Apply decay factor to both attractive and repulsive gradients equally
            // https://arxiv.org/pdf/1802.03426
            // Instead, we decrease repulsive forces only, to emphasize local neighbourhoods later in the process
            // Could use more complex scaling if we want ...
            let attractAlpha = MLXArray(1.0)
            var atractGradient = ag.first!
            
            let repulsiveAlpha = MLXArray(1.0 - ( Float(epoch) / Float(epochs) ))
            var repusliveGradient = rg.first!
            
            
            
            
            if atractGradient.asArray(Float.self).contains(where: { $0.isNaN }) {
                //print("ATTRACTIVE GRADIENT CONTAINS NAN")
                print(String(format: "Epoch %3d: ∇ Loss = %8.4f | αA = %6.4f | αR = %6.4f",
                             epoch,
                             deltaLoss,
                             attractAlpha.item(Float.self),
                             repulsiveAlpha.item(Float.self)))
                atractGradient = nanToNum(atractGradient)
            }
            
            if repusliveGradient.asArray(Float.self).contains(where: { $0.isNaN }) {
                //print("REPULSIVE GRADIENT CONTAINS NAN")
                print(String(format: "Epoch %3d: ∇ Loss = %8.4f | αA = %6.4f | αR = %6.4f",
                             epoch,
                             deltaLoss,
                             attractAlpha.item(Float.self),
                             repulsiveAlpha.item(Float.self)))
                repusliveGradient = nanToNum(repusliveGradient)
            }
            
            let gradient = clip(attractAlpha * atractGradient + repulsiveAlpha * repusliveGradient, min: -10, max: 10)
            
            // Guard rails!
            // TODO: Some debugging left with different distance metrics causing NaN in (attractive?) gradients
            guard !gradient.asArray(Float.self).contains(where: { $0.isNaN }) else {
                print(String(format: "Epoch %3d: ∇ Loss = %8.4f | αA = %6.4f | αR = %6.4f",
                             epoch,
                             deltaLoss,
                             attractAlpha.item(Float.self),
                             repulsiveAlpha.item(Float.self)))
                break
            }
            
            
            (self.embedding, state) = optimizer.applySingle(gradient: gradient, parameter: self.embedding, state: state)
            
            assert( !embedding.asArray(Float.self).contains{ $0.isNaN } )
            
            if epoch % 25 == 0 {
                print(String(format: "Epoch %3d: ∇ Loss = %8.4f | αA = %6.4f | αR = %6.4f",
                             epoch,
                             deltaLoss,
                             attractAlpha.item(Float.self),
                             repulsiveAlpha.item(Float.self)))
                //makeScatterPlot(embedding, dataSetName: "GPUMAP_epoch_\(epoch)")
            }
        }
        
        //print("GPUMAP END")
        //makeScatterPlot(embedding, dataSetName: "GPUMAP_END")
    }
    
}

