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

import MLX

extension DBScan {
    internal class Point: Equatable, Identifiable, Hashable {
        typealias Label = Int
        
        var id: String { value.description }
        var value: MLXArray // TODO: We can probably speed this up by using a pointer here ... but that's only a guess
        var label: Label?
        var index: Int
        
        /// Create a new point
        /// - Parameters:
        ///   - value: The value of the point (MLXArray)
        ///   - index: The index of the point
        init(_ value: MLXArray, index: Int) {
            self.value = value
            self.index = index
        }
        
        // Equatable conformance
        static func == (lhs: Point, rhs: Point) -> Bool {
            return lhs.value.arrayEqual(rhs.value).item()
        }
        
        // Hashable conformance
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
