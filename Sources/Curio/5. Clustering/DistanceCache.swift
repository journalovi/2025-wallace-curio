//
//  Synchronized Cache.swift
//  Curio
//
//  Created by Jim Wallace on 2025-03-11.
//

import Foundation
import Synchronization

public final class DistanceCache: @unchecked Sendable {
    
    private var cache: [Int: Double] = [:]
    private let lock: Mutex<Bool> = Mutex(false)
    
    public func value(for key: Int) -> Double? {
        
        return lock.withLock {_ in
            cache[key]
        }
    }
    
    public func set(_ value: Double, for key: Int) {
        return lock.withLock {_ in
            cache[key] = value
        }
    }
        
    public subscript(key: Int) -> Double? {
        
        get {
            return lock.withLock { _ in
                cache[key]
            }
        }
        
        set {
            lock.withLock { _ in
                cache[key] = newValue
            }
        }
    }
}
