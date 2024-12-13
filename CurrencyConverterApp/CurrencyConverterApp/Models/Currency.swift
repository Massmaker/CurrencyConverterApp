//
//  Currency.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation

enum Currency: String, CaseIterable {
    case usd, eur, jpy, cad, uah, cny, gbp, ils
}

extension Currency: CurrencyAPIRequestParameterValueConvertible {
    func currencyAPIRequestParameterValue() -> String {
        return self.rawValue.uppercased()
    }
}

extension Currency {
    static func createFromString(_ input:String) -> Currency? {
        let lowercased = input.lowercased()
        return Currency(rawValue: lowercased)
    }
}
