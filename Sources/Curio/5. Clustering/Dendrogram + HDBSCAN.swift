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

extension Dendrogram {

    func condense(minClusterSize: Int) {
        guard let root = root else { return }
        
        var stack: [DendroNode] = [root]
        var outputStack: [DendroNode] = []
        
        // First traversal: Build post-order stack.
        while !stack.isEmpty {
            let currentNode = stack.removeLast()
            outputStack.append(currentNode)
            if let children = currentNode.children {
                stack.append(contentsOf: children)
            }
        }
        
        // Second phase: Process nodes in post-order for condensation.
        while !outputStack.isEmpty {
            let currentNode = outputStack.removeLast()
            if let children = currentNode.children {
                for child in children {
                    // Merge child up if it is below the minimum cluster size.
                    if child.points.count < minClusterSize {
                        currentNode.merge(with: child)
                    }
                }
                // (We've removed the forced merge for a single remaining child to avoid over-collapsing.)
            }
        }
    }

    func extractClusters() -> Set<DendroNode> {
        guard let root = root else { return [] }
        
        var stack: [DendroNode] = [root]
        var outputStack: [DendroNode] = []
        var selectedClusters: Set<DendroNode> = []
        
        // First traversal: Build post-order stack.
        while !stack.isEmpty {
            let currentNode = stack.removeLast()
            outputStack.append(currentNode)
            if let children = currentNode.children {
                stack.append(contentsOf: children)
            } else {
                // Leaf nodes start out as selected clusters.
                selectedClusters.insert(currentNode)
            }
        }
        
        // Second phase: Process nodes in post-order to propagate stability and select clusters.
        while !outputStack.isEmpty {
            let currentNode = outputStack.removeLast()
            if let children = currentNode.children {
                let sumOfChildStabilities = children.reduce(0) { $0 + $1.stability }
                if sumOfChildStabilities > currentNode.stability {
                    currentNode.stability = sumOfChildStabilities
                } else {
                    // Select the current node as a cluster and remove its children.
                    selectedClusters.insert(currentNode)
                    for child in children {
                        selectedClusters.remove(child)
                    }
                }
            }
        }
        
        // Final filtering: Remove any selected node that is a descendant of another selected node.
        let finalClusters = selectedClusters.filter { cluster in
            var current = cluster.parent
            while let parent = current {
                if selectedClusters.contains(parent) {
                    return false
                }
                current = parent.parent
            }
            return true
        }
        
        return Set(finalClusters)
    }
}
