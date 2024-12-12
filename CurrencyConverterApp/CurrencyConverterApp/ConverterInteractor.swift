//
//  ConverterInteractor.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//


import Combine

protocol PendingRequestPublisherContainer {
    var isPendingRequest:AnyPublisher<Bool, Never> { get }
}

protocol CountdownActivePublisherContainer {
    var isCountdownActive:AnyPublisher<Bool, Never> { get }
}

protocol CurrencyConversionInteraction: PendingRequestPublisherContainer {
    func convertValue(_ value:Double, fromCurrency:Currency, toCurrency:Currency) throws -> AnyPublisher<Result<Double, Error>, Never>
}

class ConverterInteractor {
    
    struct RequestInfo: CurrencyConversionRequestInfo {
        let fromValue: Double
        let fromCurrency: Currency
        let toCurrency: Currency
    }
    
    private var requestCancellable:AnyCancellable?
    private var resultPassThrough:PassthroughSubject<Result<Double, Error>, Never>?
    private lazy var _isPending:CurrentValueSubject<Bool, Never> = .init(false)
    
    let converter: any CurrencyConversion
    
    init(with converter: any CurrencyConversion) {
        self.converter = converter
    }
    
    func convertValue(_ value:Double, from inputCurrency:Currency, to outputCurrency:Currency) -> AnyPublisher<Result<Double, Error>, Never> {
          
        let info = RequestInfo(fromValue: value , fromCurrency: inputCurrency, toCurrency: outputCurrency)
        
        let publisher =
        self.converter.getConversion(for: info)
        let resultPassthroughSubject:PassthroughSubject<Result<Double, Error>, Never> = .init()
        self._isPending.send(true)
        self.requestCancellable =
        publisher.sink { [weak self] completion in
            guard let self else { return }
            if case .failure( let error) = completion {
                self._isPending.send(false)
                self.handleRequestFaulire(error)
            }
        } receiveValue: { [weak self] result in // Result<any CurrencyConversionResult, any Error>
            guard let self else { return }
            self._isPending.send(false)
            
            switch result {
            case .failure(let error):
                self.handleConversionFailure(error)
            case .success(let conversionResult):
                self.handleConversionResult(conversionResult)
            }
        }
        
        self.resultPassThrough = resultPassthroughSubject
        
        return resultPassthroughSubject.eraseToAnyPublisher()

    }
    
    
    private func handleConversionResult(_ result: any CurrencyConversionResult) {
        defer {
            self.requestCancellable?.cancel()
            self.requestCancellable = nil
            self.resultPassThrough = nil
        }
        
        let convertedValue = result.value
        
        self.resultPassThrough?.send(Result.success(convertedValue))
    }
    
    private func handleConversionFailure(_ error:any Error) {
        defer {
            self.requestCancellable?.cancel()
            self.requestCancellable = nil
            self.resultPassThrough = nil
        }
        /// here can be some advanced error handling
        self.resultPassThrough?.send(Result.failure(PrimitiveUITextError.failedToConvert))
    }
    
    private func handleRequestFaulire(_ error: any Error) {
        defer {
            self.requestCancellable = nil
            self.resultPassThrough = nil
        }
        self.resultPassThrough?.send(Result.failure(PrimitiveUITextError.networkingIssue))
    }
}

//MARK: - PendingRequestPublisherContainer
extension ConverterInteractor: PendingRequestPublisherContainer {
    var isPendingRequest:AnyPublisher<Bool, Never> {
        self._isPending.eraseToAnyPublisher()
    }
}

//MARK: - CurrencyConversionInteraction
extension ConverterInteractor: CurrencyConversionInteraction {
    func convertValue(_ value:Double, fromCurrency:Currency, toCurrency:Currency) throws -> AnyPublisher<Result<Double, Error>, Never> {
        
        guard fromCurrency != toCurrency else {
            throw CurrencyInputError.equalInputAndOutput
        }
        
        return self.convertValue(value, from: fromCurrency, to: toCurrency)
    }
}
