// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Curio",
    platforms: [
            .macOS(.v15)
    ],
    products: [
        .library(
            name: "Curio",
            targets: ["Curio"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/L1MeN9Yu/Elva", .upToNextMajor(from: "2.1.3")),
        .package(url: "https://github.com/JadenGeller/similarity-topology", .upToNextMajor(from: "0.1.14")),
        .package(url: "https://github.com/MacPaw/OpenAI.git", .exact("0.2.5")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.0")),
        .package(url: "https://github.com/ml-explore/mlx-swift", .upToNextMajor(from: "0.21.3")),
        .package(url: "https://github.com/jkrukowski/SwiftFaiss", .upToNextMajor(from: "0.0.8")),
        .package(url: "https://github.com/huggingface/swift-transformers", .upToNextMajor(from: "0.1.17")),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", .upToNextMajor(from: "2.21.1")),
    ],
    targets: [
        .target(
            name: "Curio",
            dependencies: [
                .product(name: "HNSWAlgorithm", package: "similarity-topology"),
                .product(name: "ZSTD", package: "Elva"),
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "HeapModule", package: "swift-collections"),
                .product(name: "SwiftFaiss", package: "SwiftFaiss", condition: .when(platforms: [.macOS])),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLinalg", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "MLXLLM", package: "mlx-swift-examples")
                //.product(name: "OpenMP"),
            ],
            resources: [
                .copy("Resources/all-MiniLM-L6-v2"),
                .copy("Resources/potion-base-8m"),
                .copy("Resources/potion-base-32m"),
                .copy("Resources/Llama-3.2-1B-Instruct-4bit"),
                //.copy("Resources/Phi-4-mini-instruct-8bit"),
                .process("Resources/all-MiniLM-L6-v2/all-MiniLM-L6-v2.mlpackage"),
            ],
            swiftSettings: [
                .define("ENABLE_TESTABILITY", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "CurioTests",
            dependencies: ["Curio"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
