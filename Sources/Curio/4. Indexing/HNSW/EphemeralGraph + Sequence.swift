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

/**
 
 Usage:
 
 for (level, key, neighbors) in graph {
    ...
 }
 
 To iterate without Sequence conformance, use:
 
 for level in graph.connections.keys {
    for key in graph.keys(on: level) {
        ...
        // use graph[key, level] to get the set of neighbors or other subscripting tasks
    }
 }
 
*/

/// Sequence conformance allows us to iterate through the levels of the hiearchical graph
extension EphemeralGraph: Sequence {
    public typealias Element = (Level, Key, Set<Key>)
    
    public struct EphemeralGraphIterator: IteratorProtocol {
        private var levelIterator: Dictionary<Level, [Key: Set<Key>]>.Iterator
        private var currentLevel: (key: Level, value: [Key: Set<Key>])?
        private var keyIterator: Dictionary<Key, Set<Key>>.Iterator?
        
        init(_ graph: EphemeralGraph<Key, Level>) {
            self.levelIterator = graph.connections.makeIterator()
            self.currentLevel = self.levelIterator.next()
            if let current = self.currentLevel {
                self.keyIterator = current.value.makeIterator()
            }
        }
        
        public mutating func next() -> Element? {
            guard let currentLevel = currentLevel else { return nil }
            
            if let nextKey = keyIterator?.next() {
                // Return the current level, key, and the set of neighbors
                return (currentLevel.key, nextKey.key, nextKey.value)
            } else {
                // Move to the next level
                self.currentLevel = levelIterator.next()
                guard let nextLevel = self.currentLevel else { return nil }
                self.keyIterator = nextLevel.value.makeIterator()
                return next()
            }
        }
    }
    
    public func makeIterator() -> EphemeralGraphIterator {
        return EphemeralGraphIterator(self)
    }
}
