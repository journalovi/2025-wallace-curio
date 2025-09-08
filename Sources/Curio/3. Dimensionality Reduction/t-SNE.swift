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
import MLXRandom
import Synchronization

/// A Stochastic Neighbor Embedding (t-SNE) reducer
public final class tSNE: SNLPReducer, @unchecked Sendable {
    
    
    public enum InitialValues {
        case random
        case pca
        case laplacian
    }
    
    let targetDimensions: Int
    let perplexity: Float
    let learningRate: Float
    let initialValues: InitialValues
    let earlyExaggeration: Float
    let maxIterations: Int
    let breakIn: Int
    let patience: Int
    let minimumGradientNorm: Float
    //let metric: DistanceMetric
    let batchSize: Int
    let numThreads: Int
    
    var klDivergence: Float? = nil
    
    // Keep these around as working copies
    internal var hdEmbeddings: MLXArray = MLXArray(0)
    internal var kNNIndex: (any SNLPIndex)?
    internal let ldEmbeddingsMutex: Mutex<MLXArray> = Mutex(MLXArray(0)) // This is the most important thing to synchronize across Tasks
    
    internal var computeValueAndGradient: ([MLXArray]) -> ([MLXArray], [MLXArray])
    //internal var compiledHDAffinities: (MLXArray) -> MLXArray
    //internal var compiledLDAffinities: (MLXArray) -> MLXArray
    //internal var compiledLoss: ([MLXArray]) -> [MLXArray]
    //internal var compiledSGD: () -> ()
    
    /// Initialize a new t-SNE reducer with the specified target dimensions
    /// - Parameter targetDimensions: The number of dimensions to reduce to
    required convenience init(targetDimensions: Int = 2) {
        self.init(
            targetDimensions: targetDimensions,
            perplexity: 15.0,
            learningRate: 100.0,
            initialValues: .random,
            earlyExaggeration: 12.0,
            maxIterations: 5000,
            breakIn: 500,
            patience: 500,
            minimumGradientNorm: 1e-8,
            metric: EuclideanDistance(),
            batchSize: 1024,
            numThreads: max(1, ProcessInfo.processInfo.activeProcessorCount - 2)
        )
    }
    
    /// Initialize a new t-SNE reducer with the specified parameters
    /// - Parameters:
    ///   - targetDimensions: The number of dimensions to reduce to
    ///   - perplexity: The perplexity parameter
    ///   - learningRate: The learning rate
    ///   - earlyExaggeration: The early exaggeration parameter
    ///   - maxIterations: The maximum number of iterations
    ///   - breakIn: The number of iterations to break in
    ///   - patience: The number of iterations to wait before breaking
    ///   - minimumGradientNorm: The minimum gradient norm to continue
    ///   - metric: The distance metric to use
    ///   - batchSize: The batch size for optimization
    ///   - numThreads: The number of threads to use
    init(
        targetDimensions: Int = 2,
        perplexity: Float = 15.0,
        learningRate: Float = 100.0,
        initialValues: InitialValues = .random,
        earlyExaggeration: Float = 12.0,
        maxIterations: Int = 5000,
        breakIn: Int = 500,
        patience: Int = 500,
        minimumGradientNorm: Float = 1e-8,
        metric: DistanceMetric = EuclideanDistance(),
        batchSize: Int = 1024,
        numThreads: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 2)
    ) {
        self.targetDimensions = targetDimensions
        self.perplexity = perplexity
        self.learningRate = learningRate
        self.initialValues = initialValues
        self.earlyExaggeration = earlyExaggeration
        self.maxIterations = maxIterations
        self.breakIn = breakIn
        self.patience = patience
        self.minimumGradientNorm = minimumGradientNorm
        //self.metric = metric
        self.batchSize = batchSize
        self.numThreads = numThreads
        self.hdEmbeddings = MLXArray(0)
        //self.ldEmbeddings = nil
        //self.kNNIndex = FAISS(dimensions: 50, metricType: .l2)
        self.computeValueAndGradient = { _ in  ([MLXArray(0)], [MLXArray(0)]) }
        //self.compiledHDAffinities = compile(tSNE.computeHighDimAffinities)
        //self.compiledLDAffinities = compile(tSNE.computeLowDimAffinities)
        //self.compiledSGD = compile( (gradientDescent)
        //self.compiledLoss = compile(tSNE.loss)
    }
    

    /// Reduce a corpus in place
    /// - Parameter corpus: The `SNLPCorpus` corpus to reduce
    func reduceCorpus<C: SNLPCorpus>(_ corpus: inout C) async {
        var indexedCorpus = await IndexedCorpus(corpus)
        await reduceCorpus(&indexedCorpus)
        corpus.encodedDocuments = indexedCorpus.encodedDocuments
        corpus.dimensions = targetDimensions
        
        if var indexedCorpus = corpus as? any SNLPIndexedCorpus {
            await indexedCorpus.rebuildIndex()
        }
    }
    
    
    func reduceCorpus<C: SNLPIndexedCorpus>(_ corpus: inout C) async {
        
        // If we have more than > 30 dimensions, reduce with PCA first
//        if corpus.dimensions  > 50 {
//            let pca = PCA(targetDimensions: 50)
//            pca.reduce(&corpus.encodedDocumentsAsMLXArray, normalize: false)
//            corpus.dimensions = 50
//            await corpus.rebuildIndex()
//        }
        self.hdEmbeddings = corpus.encodedDocumentsAsMLXArray
        self.kNNIndex = corpus.index
        
        guard let kNNIndex else {
            fatalError("kNNIndex is nil")
        }
        
        // 2. Initialize low-dimensional embedding using a fast method
        switch initialValues {
        case .random:
            ldEmbeddingsMutex.withLock { ld in
                ld = uniform(-0.01..<0.01, [hdEmbeddings.shape[0], targetDimensions])
            }
        case .pca:
                                   
            var copy = corpus.copy()
            let pca = PCA(targetDimensions: targetDimensions)
            pca.reduce(&copy.encodedDocumentsAsMLXArray)
            
            assert( copy.encodedDocumentsAsMLXArray.shape == [hdEmbeddings.shape[0], targetDimensions])
            
            ldEmbeddingsMutex.withLock { ld in
                ld = copy.encodedDocumentsAsMLXArray
            }
        case .laplacian:
            
            var copy = corpus.copy()
            let fsc = await FuzzySimplicialComplex(hdEmbeddings, index: kNNIndex, k: Int(perplexity))

            let laplacian = LaplacianReducer(targetDimensions: targetDimensions, fsc: fsc)
            laplacian.reduce(&copy.encodedDocumentsAsMLXArray)
            
            assert( copy.encodedDocumentsAsMLXArray.shape == [hdEmbeddings.shape[0], targetDimensions])
            
            ldEmbeddingsMutex.withLock { ld in
                ld = copy.encodedDocumentsAsMLXArray
            }
        }
        
        
        // 3. Perform gradient descent to optimize embedding
        await gradientDescent()
                
        corpus.encodedDocumentsAsMLXArray = ldEmbeddingsMutex.withLock { ld in
            
            //let d = ld.asData(access: .copy)
            let f = ld.asArray(Float.self)  // TODO: Why isn't asData working here?
            return MLXArray(f, [hdEmbeddings.shape[0], targetDimensions])
        }
        corpus.dimensions = targetDimensions
        await corpus.rebuildIndex()
    }
}
