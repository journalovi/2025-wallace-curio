import Foundation
import Accelerate
import MLX
import MLXLinalg
import MLXOptimizers

struct UMAP: SNLPReducer {
    
    var targetDimensions: Int
    var numNeighbours: Int = 10
    var minDistance: Float = 0.1
    var spread: Float = 1.0
    var minEpochs: Int = 25
    var maxEpochs: Int = 500
    var negativeSampleRate: Int = 5
    var initialValues: InitialValues = .random
    
    // Attractive Learning Rate Parameters
    var attrLearningRate: Float = 1.0
    var attrDecay: Float = 0.99
    let convergenceThreshold: Float = 1e-5
    let minLearningRate: Float = 1e-5 // Minimum learning rate to avoid complete stagnation
    let learningRateIncreaseFactor: Float = 1.1 // Factor to increase learning rate if stuck
    let maxEpochWithoutProgress = 20 // Number of epochs without improvement before adjusting

    // Repulsive Learning Rate Parameters
    var replLearningRate: Float = 1.0
    var replDecay: Float = 0.9
    
    
    internal var a: Float = 1.577
    internal var b: Float = 0.895
    
    init(targetDimensions: Int) {
        self.targetDimensions = targetDimensions
        setABParameters(spread: spread, minDist: minDistance)
    }
    
    init(targetDimensions: Int,
         numNeighbours: Int,
         minDistance: Float = 0.1,
         spread: Float = 1.0,
         minEpochs: Int = 25,
         maxEpochs: Int = 500,
         attrLearningRate: Float = 1.0,
         attrDecay: Float = 0.99,
         negativeSampleRate: Int = 5,
         replLearningRate: Float = 1.0,
         replDecay: Float = 0.9,
         initialValues: InitialValues = .random) async {
        self.targetDimensions = targetDimensions
        self.numNeighbours = numNeighbours
        self.minDistance = minDistance
        self.spread = spread
        self.minEpochs = minEpochs
        self.maxEpochs = maxEpochs
        self.attrLearningRate = attrLearningRate
        self.attrDecay = attrDecay
        self.negativeSampleRate = negativeSampleRate
        self.replLearningRate = replLearningRate
        self.replDecay = replDecay
        self.initialValues = initialValues
        setABParameters(spread: spread, minDist: minDistance)
    }
    
    func reduceCorpus<C: SNLPCorpus>(_ corpus: C) async -> C {
        precondition(corpus.encodedDocuments.allSatisfy { $0.count >= targetDimensions }, "All embeddings must be longer than target dimension.")
        
        var result = corpus.copy()
        await reduceCorpus(&result)
        return result
    }
    
    /// Reduce a corpus in place
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    func reduceCorpus<C: SNLPCorpus>(_ corpus: inout C) async {
        
        // Reduce dimensionality with PCA, but keep 9% of variance
        if corpus.dimensions > 50 {
            let pca = PCA(targetDimensions: 50)
            pca.reduce(&corpus.encodedDocumentsAsMLXArray, explainedVariance: 0.95)
            corpus.dimensions = corpus.encodedDocumentsAsMLXArray.shape[1]
        }

        // Normalize data
        var data = corpus.encodedDocumentsAsMLXArray
        let mean = mean(data, axis: 0)
        let std = std(data, axis: 0)
        data = (data - mean) / maximum(std, 1e-18)
        corpus.encodedDocumentsAsMLXArray = data
        
        // If we already have an SNLPIndex, use it
        if var indexedCorpus = corpus as? any SNLPIndexedCorpus {
            await indexedCorpus.rebuildIndex()
            
            await _fit(&indexedCorpus)
            corpus.dimensions = targetDimensions
            corpus.encodedDocuments = indexedCorpus.encodedDocuments
            return
        }
        
        var indexedCorpus = await IndexedCorpus(corpus)
        await indexedCorpus.rebuildIndex()
        
        await _fit(&indexedCorpus)
        corpus.encodedDocuments = indexedCorpus.encodedDocuments
        corpus.dimensions = targetDimensions
        //await indexedCorpus.rebuildIndex()
    }
    
    // Calculate the parameters 'a' and 'b' based on 'spread' and 'min_dist'
    @inlinable
    internal mutating func setABParameters(spread: Float = 1.0, minDist: Float = 0.1) {
        // Use nonlinear least squares to determine 'a' and 'b'
        var a: Double = 1.0
        var b: Double = 1.0
        let spread = Double(spread)
        let minDist = Double(minDist)
        
        let targetCurve: (Double) -> Double = { distance in
            if distance < minDist {
                return 1.0
            } else {
                return exp(-(distance - minDist) / spread)
            }
        }
        
        let optimizationFunction: (Double, Double) -> Double = { a, b in
            var error: Double = 0.0
            for distance in stride(from: 0.0, to: 5.0, by: 0.1) {
                let predicted = 1.0 / (1.0 + a * pow(distance, 2.0 * b))
                let target = targetCurve(distance)
                error += pow(predicted - target, 2)
            }
            return error
        }
        
        // Simple optimization loop
        let learningRate: Double = 0.01
        let maxIterations: Int = 1000
        for _ in 0 ..< maxIterations {
            let gradientA = (optimizationFunction(a + 1e-5, b) - optimizationFunction(a, b)) / 1e-5
            let gradientB = (optimizationFunction(a, b + 1e-5) - optimizationFunction(a, b)) / 1e-5
            
            a -= learningRate * gradientA
            b -= learningRate * gradientB
        }
        
        self.a = Float(a)
        self.b = Float(b)
    }

}


extension UMAP {
    
    internal func _fit<C: SNLPIndexedCorpus>(_ corpus: inout C) async {
        
        let umapModule = await UMAPModule(&corpus, targetDimensions: targetDimensions, numNeighbours: numNeighbours, negativeSampleRate: negativeSampleRate, initialValues: initialValues, distanceMetric: corpus.metric, a: a, b: b)

        let optimizer = SGD(learningRate: 1.0) //, momentum: 0.8)
        
        umapModule.optimizeEmbedding(optimizer: optimizer, epochs: maxEpochs)
        
        corpus.encodedDocumentsAsMLXArray = umapModule.embedding
        corpus.dimensions = targetDimensions
        await corpus.rebuildIndex()
        
        assert( !corpus.encodedDocuments.contains{ vector in
            vector.contains{ $0.isNaN }
        }, "UMAP Failed: Encoded documents should not contain NaN values.")
    }
}
