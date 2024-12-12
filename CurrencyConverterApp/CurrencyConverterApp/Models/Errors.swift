//
//  Errors.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

enum PreparationError:Error {
    case badURL
}

enum DecodingFailure:Error {
    case faileToDecode
}

enum CurrencyResponseFailure: Error {
    case badResponseData
    case badResponseCode(Int)
    case badURLResponse
}
