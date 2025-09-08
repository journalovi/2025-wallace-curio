//
//  Parameter.swift
//  SwiftNLP
//
//  Created by Jim Wallace on 2024-11-26.
//

enum Parameter<Value> {
    case value(Value)       // For explicitly specified values
    case `default`          // To use a predefined default value
    case none               // To indicate the absence of a value
    case auto               // For dynamically determined values
}
