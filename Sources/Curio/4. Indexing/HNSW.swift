//// Copyright (c) 2024 Jim Wallace
////
//// Permission is hereby granted, free of charge, to any person
//// obtaining a copy of this software and associated documentation
//// files (the "Software"), to deal in the Software without
//// restriction, including without limitation the rights to use,
//// copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the
//// Software is furnished to do so, subject to the following
//// conditions:
////
//// The above copyright notice and this permission notice shall be
//// included in all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//// OTHER DEALINGS IN THE SOFTWARE.
////
//// The HNSW work is based on the original work of Jaden Geller
//// See the https://github.com/JadenGeller/similarity-topology.git
//// for reference. The code is used with permission from the author
//// under the MIT License.
////
//// Created by Mingchung Xia on 2024-02-14.
////
//
//import Foundation
//import MLX
//
//struct HNSW: SNLPIndex, @unchecked Sendable {
//
//    
//    internal var index: DeterministicEphemeralVectorIndex<[Float]>
//    internal var typicalNeighborhoodSize: Int { index.typicalNeighborhoodSize }
//
//    init() {
//        self.init(typicalNeighborhoodSize: 20)
//    }
//    
//    init(typicalNeighborhoodSize: Int = 20) {
//        self.index = DeterministicEphemeralVectorIndex<[Float]>(typicalNeighborhoodSize: typicalNeighborhoodSize)
//    }
//    
//    @inlinable
//    mutating func insert(_ vector: [Float]) {
//        index.insert(vector)
//    }
//    
//    mutating func insert(_ vector: MLX.MLXArray) async {
//        index.insert(vector.asArray(Float.self))
//    }
//    
//    
//    @inlinable
//    func find(near query: [Float], limit: Int) -> [Int] {
//        let results = try! index.find(near: query, limit: limit)
//        return results.map{ $0.id }
//    }
//    
//    func find(near query: MLX.MLXArray, limit: Int) async -> [Int] {
//        let results = try! index.find(near: query.asArray(Float.self), limit: limit)
//        return results.map{ $0.id }
//    }
//    
//}
