//
//  EdgeList.swift
//  Curio
//
//  Created by Jim Wallace on 2025-03-11.
//

import Foundation
import Synchronization

class SynchronizedEdgeList: @unchecked Sendable {
    private var edgeList: [Edge?]
    private let lock: Mutex<Bool> = Mutex(false)
    
    init(count: Int) {
        self.edgeList = Array(repeating: nil, count: count)
    }
    
    var edges: [Edge?] {
        get {
            lock.withLock { _ in
                edgeList
            }
        }
        set {
            lock.withLock { _ in
                edgeList = newValue
            }
        }
    }
    
    func reset(count: Int) {
        lock.withLock{ _ in
            edgeList = Array(repeating: nil, count: count)
        }
    }
    
    func update(vertex: Int, edge: Edge) {
        lock.withLock { _ in
            if let cheapest = edgeList[vertex], cheapest.weight < edge.weight {
                return
            }
            edgeList[vertex] = edge
        }
    }
    
}
