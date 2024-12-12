//
//  CurrencyConversionResponse.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation

struct CurrencyConversionResponse:Decodable {
    var currency: String
    
    var value: Double
}
