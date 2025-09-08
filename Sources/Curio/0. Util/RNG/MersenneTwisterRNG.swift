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
//
// See the https://github.com/JadenGeller/similarity-topology.git
// for reference. The code is used with permission from the author
// under the MIT License.
//
// GameplayKit provides a mersenne twister for RNG, but is not available on Linux
// See https://github.com/quells/Squall package for alternative mersenne twister

#if canImport(GameplayKit) && os(macOS)
import Foundation
import GameplayKit

@available(macOS, introduced: 10.11)
public struct MersenneTwisterRNG: RandomNumberGenerator {
    private let randomSource: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        randomSource = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating public func next() -> UInt64 {
        let upperBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt()))) << 32
        let lowerBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt())))
        return upperBits | lowerBits
    }
}

#endif
