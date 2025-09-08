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

public protocol SNLPEncoder: Sendable {
    
    var zeroes: [Float] { get }
    var dimensions: Int { get }
    
    init() async
        
    @inlinable
    func encodeSentence(_ sentence: String) async -> [Float]
    
}

extension SNLPEncoder {
    
    public var zeroes: [Float] { MLXArray.zeros([1, dimensions]).asArray(Float.self) }
    
    @inlinable
    public func encodeSentences(documents: [any SNLPDataItem], indices: Range<Int>) async -> [[Float]] {
        
        var result = [[Float]]()
        
        for (_, idx) in indices.enumerated() {
            result.append( await encodeSentence( documents[idx].fullText ) )
        }
        
        return result
    }
    
    @inlinable
    public func encodeSentences(documents: [any SNLPDataItem], encodings: inout [[Float]], indices: Range<Int>) async {
        for idx in indices {
           encodings[idx] =  await encodeSentence( documents[idx].fullText )
        }
    }
    
}

// TODO: Test the following for performance impact
// As extensions, these should be statically dispatched.
// Not clear whether this is meaningful or not in practice?
//extension SNLPEncoder {
//    @inlinable
//    func encodeSentence(_ sentence: String) async -> [Scalar] {
//        await encodeSentence(sentence)
//    }
//}
