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

/// Union Find data structure with path compression and union by rank

import Synchronization

class UnionFind: @unchecked Sendable {
    private var parent: [Int]
    private var rank: [Int]
    
    private let lock: Mutex<Bool> = Mutex(false)
    
    /// Initialize the UnionFind data structure with a given size
    /// - Parameter size: The size of the UnionFind data structure
    init(size: Int) {
        parent = Array(0..<size)
        rank = Array(repeating: 0, count: size)
    }
    
    /// Find the parent of a node
    /// - Parameter node: The node to find the parent of
    /// - Returns: The parent of the node
    func find(_ node: Int) -> Int {
        
        return lock.withLock {_ in
            _find(node)
        }
    }

    /// Find the parent of a node
    /// - Parameter node: The node to find the parent of
    /// - Returns: The parent of the node
    private func _find(_ node: Int) -> Int {
        
        var current = node
        // Traverse to the root
        while parent[current] != current {
            current = parent[current]
        }
        let root = current
            
        // Path compression: make every node along the path point to the root
        current = node
        while parent[current] != current {
            let next = parent[current]
            parent[current] = root
            current = next
        }
        return root
    }
    
    /// Union two nodes into the same set
    /// - Parameters:
    ///   - u: The first node
    ///   - v: The second node
    func union(_ u: Int, _ v: Int) {
        lock.withLock {_ in

            let rootU = _find(u)
            let rootV = _find(v)
        
            if rootU != rootV {
                if rank[rootU] > rank[rootV] {
                    parent[rootV] = rootU
                } else if rank[rootU] < rank[rootV] {
                    parent[rootU] = rootV
                } else {
                    parent[rootV] = rootU
                    rank[rootU] += 1
                }
            }
        }
    }
}
