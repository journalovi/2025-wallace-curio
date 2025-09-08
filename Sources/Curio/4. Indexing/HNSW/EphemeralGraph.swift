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
// This is modified from the similarity-topology package by Jaden Geller under the MIT License.
//

import Foundation
import HNSWAlgorithm

/// A graph manager that can be used to manage a graph of elements by key and level
public class EphemeralGraph<Key: Hashable, Level: BinaryInteger>: GraphManager {
    private struct NeighborhoodID: Hashable {
        var key: Key
        var level: Level
    }
    
    public init() { }
    
    public var entry: (level: Level, key: Key)?
    public var connections: [Level: [Key: Set<Key>]] = [:]
    
    @inlinable
    subscript(level: Level, key: Key) -> Set<Key> {
        get { connections[level, default: [:]][key, default: []] }
        set { connections[level, default: [:]][key, default: []] = newValue }
    }
    
    @inlinable
    public func neighborhood(on level: Level, around key: Key) -> [Key] {
        Array(self[level, key])
    }
    
    @inlinable
    public func connect(on level: Level, _ keys: (Key, Key)) {
        self[level, keys.0].insert(keys.1)
        self[level, keys.1].insert(keys.0)
    }
    
    @inlinable
    public func disconnect(on level: Level, _ keys: (Key, Key)) {
        self[level, keys.0].remove(keys.1)
        self[level, keys.1].remove(keys.0)
    }
    
    @inlinable
    public func remove(on level: Level, key: Key) {
        connections[level, default: [:]].removeValue(forKey: key)
    }
}

extension EphemeralGraph {
    public func keys(on level: Level) -> some Sequence<Key> {
        var result = Set(connections[level, default: [:]].keys)
        if let entry, entry.level == level {
            result.insert(entry.key)
        }
        return result
    }
}

extension EphemeralGraph {
    public func apply(_ transform: (EphemeralGraph<Key, Level>) -> EphemeralGraph<Key, Level>) -> EphemeralGraph<Key, Level> {
        return transform(self)
    }
}
