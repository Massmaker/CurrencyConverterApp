//
//  CurrencyConversionInteractorDummy.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation
import Combine

class CurrencyConversionInteractorDummy: CurrencyConversionInteraction {
    func convertValue(_ value: Double, fromCurrency: Currency, toCurrency: Currency) throws -> AnyPublisher<Result<Double, any Error>, Never> {
        let randomResult = [24.6, Double(35), Double(100500)].randomElement() ?? Double(10)
        return Just(.success(randomResult)).eraseToAnyPublisher()
    }
    
    var isPendingRequest: AnyPublisher<Bool, Never> {
        return _isPending.eraseToAnyPublisher()
    }
    private let _isPending:CurrentValueSubject<Bool, Never> = .init(false)
    
}
