//
//  Currency.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation

enum Currency: String {
    case usd, jpy, cad, uah, eur, cny, gbp, ils
}

extension Currency: CurrencyAPIRequestParameterValueConvertible {
    func currencyAPIRequestParameterValue() -> String {
        return self.rawValue.uppercased()
    }
}
