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
import NaturalLanguage

struct SNLPTokenization {
    
    static let unwantedCharacters: CharacterSet = CharacterSet.punctuationCharacters
                                                .union(.symbols)
                                                .union(.decimalDigits)
                                                .union(.controlCharacters)
    
    /**
     Converts text to lowercase, removes unwanted characters, removes stopwords, and tokenizes based on whitespace.
     
     - Parameters:
        - text: The input text to be processed.
        - characterFilters: Character set for unwanted characters.
        - tokenFilters: Set of stopwords to remove.
        - nGramRange: Range for generating n-grams (e.g., 1...2 for unigrams and bigrams).
     - Returns: Array of tokenized and filtered words including n-grams.
     */
    static func applyBasicTextProcessing(
        _ text: String,
        characterFilters: CharacterSet = unwantedCharacters,
        tokenFilters: Set<String> = NLTKStopwordSet,
        nGramRange: ClosedRange<Int> = 1...1
    ) -> [String] {
        // Remove characters contained in characterFilters
        let wordsWithoutPunctuation = text
            .components(separatedBy: characterFilters)
            .joined()
            .split(separator: " ")
            .map { $0.lowercased() }
        
        let filteredTokens = wordsWithoutPunctuation.filter { !tokenFilters.contains($0) }
        
        var nGrams: Set<String> = []
        
        // Generate n-grams based on the provided range
        for n in nGramRange {
            guard n > 0 else { continue }
            if n == 1 {
                nGrams.formUnion(filteredTokens)
            } else {
                for i in 0..<(filteredTokens.count >= n ? filteredTokens.count - n + 1 : 0) {
                    let nGram = filteredTokens[i..<(i + n)].joined(separator: " ")
                    nGrams.insert(nGram)
                }
            }
        }
        
        return Array(nGrams)
    }
    
    /**
     Applies text processing including lemmatization, POS tagging, and n-gram generation.
     
     - Parameters:
        - text: The input text to be processed.
        - characterFilters: Character set for unwanted characters.
        - tokenFilters: Set of stopwords to remove.
        - nGramRange: Range for generating n-grams (e.g., 1...2 for unigrams and bigrams).
        - language: The language used for lemmatization and POS tagging.
     - Returns: Array of tokens filtered by POS and lemmatized, including n-grams.
     */
    static func applyTextProcessingWithLemmatizationAndPOS(
        _ text: String,
        characterFilters: CharacterSet = unwantedCharacters,
        tokenFilters: Set<String> = NLTKStopwordSet,
        nGramRange: ClosedRange<Int> = 1...2, // Unigrams and bigrams
        language: NLLanguage = .english
    ) -> [String] {
        // Remove characters contained in characterFilters
        let wordsWithoutPunctuation = text
            .components(separatedBy: characterFilters)
            .joined()
        
        // Set up a tagger for lemmatization and POS tagging
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = wordsWithoutPunctuation
        
        var filteredTokens: [String] = []
        tagger.enumerateTags(in: wordsWithoutPunctuation.startIndex..<wordsWithoutPunctuation.endIndex,
                             unit: .word,
                             scheme: .lemma,
                             options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            let token = wordsWithoutPunctuation[tokenRange].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let _ = tag else {
                return true
            }
            
            filteredTokens.append(token)
            
            return true
        }
        
        // Remove stopwords as a list operation
        let finalTokens = filteredTokens.filter { !tokenFilters.contains($0) }
        
        var nGrams: Set<String> = []
        
        // Generate n-grams based on the provided range
        for n in nGramRange {
            guard n > 0 else { continue }
            if n == 1 {
                nGrams.formUnion(finalTokens)
            } else {
                for i in 0..<(finalTokens.count >= n ? finalTokens.count - n + 1 : 0) {
                    let nGram = finalTokens[i..<(i + n)].joined(separator: " ")
                    nGrams.insert(nGram)
                }
            }
        }
        
        return Array(nGrams)
    }
}
