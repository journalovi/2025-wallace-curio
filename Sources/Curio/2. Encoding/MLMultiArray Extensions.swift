import CoreML

extension MLMultiArray {
    
    static func from(_ arr: [Int], dims: Int = 1) -> MLMultiArray {
        var shape = Array(repeating: 1, count: dims)
        shape[shape.count - 1] = arr.count
        let mlArray = try! MLMultiArray(shape: shape as [NSNumber], dataType: .int32)
        let dataptr = UnsafeMutablePointer<Int32>(OpaquePointer(mlArray.dataPointer))
        for (i, item) in arr.enumerated() {
            dataptr[i] = Int32(item)
        }
        return mlArray
    }

    static func toDoubleArray(_ mlArray: MLMultiArray) -> [Double] {
        var arr: [Double] = Array(repeating: 0, count: mlArray.count)
        let dataptr = UnsafeMutablePointer<Double>(OpaquePointer(mlArray.dataPointer))
        for i in 0..<mlArray.count {
            arr[i] = Double(dataptr[i])
        }
        return arr
    }
}
