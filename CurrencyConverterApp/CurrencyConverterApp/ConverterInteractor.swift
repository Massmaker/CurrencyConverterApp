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

protocol PrimitiveErrorType {
    var title:String {get}
    var details:String? {get}
}

protocol CurrencyConversionInteraction: PendingRequestPublisherContainer {
    func convertValue(_ value:Double, fromCurrency:Currency, toCurrency:Currency) throws -> AnyPublisher<Result<Double, any Error>, Never>
}

class ConverterInteractor {
    
    struct RequestInfo: CurrencyConversionRequestInfo {
        let fromValue: Double
        let fromCurrency: Currency
        let toCurrency: Currency
    }
    
    /// Conforms to PrimitiveErrorType
    struct ResponseError:Error, PrimitiveErrorType {
        let title:String
        private(set) var details:String?
    }
    
    private var requestCancellable:AnyCancellable?
    private var resultPassThrough:PassthroughSubject<Result<Double, any Error>, Never>?
    private lazy var _isPending:CurrentValueSubject<Bool, Never> = .init(false)
    
    let converter: any CurrencyConversion
    
    init(with converter: any CurrencyConversion) {
        self.converter = converter
    }
    
    func convertValue(_ value:Double, from inputCurrency:Currency, to outputCurrency:Currency) -> AnyPublisher<Result<Double, any Error>, Never> {
        
        self._isPending.send(true)
        
        let info = RequestInfo(fromValue: value , fromCurrency: inputCurrency, toCurrency: outputCurrency)
        let resultPassthroughSubject:PassthroughSubject<Result<Double, any Error>, Never> = .init()
        
        let publisher = self.converter.getConversion(for: info)
        
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
#if DEBUG
        print(" Result Of Conversion: \(result)")
#endif
        self.resultPassThrough?.send(Result.success(convertedValue))
    }
    
    
    /// Sends a `ResponseError` if received some `NetworkingError` or an unknown error type
    private func handleConversionFailure(_ error: any Error) {
        defer {
            self.requestCancellable?.cancel()
            self.requestCancellable = nil
            self.resultPassThrough = nil
        }
        
        guard let sender = self.resultPassThrough else { return }
        
        guard let aCurrencyResponseFailure = error as? CurrencyResponseFailure else {
            sender.send(Result.failure(ResponseError(title: "Unknown error", details: "Unexpected error occured: \(error.localizedDescription)")))
            return
        }
        
        var title = "Failed to Convert Currency"
        var subtitle = ""
        
        
        switch aCurrencyResponseFailure {
        case .badResponseData:
            subtitle = "Unexpected response"
        case .badResponseFormat:
            subtitle = "Unexpected response format"
        case .badResponseCode(let stCode, let additionalError):
            subtitle = "response status code: \(stCode)"
            if let additional = additionalError {
                subtitle += "\nMessage: ' \(additional.error): \"\(additional.errorDescription ?? "")\" ' "
            }
        case .badURLResponse:
            subtitle = "Unexpected URL response"
        case .networkingError(let networkingError):
            
            switch networkingError {
            case .requestTimeout:
                subtitle = "Request timed out. Please try again later."
            case .noInternetConnection:
                subtitle = "No internet connection. Please check it and try again."
            case .otherError:
                title = "Networking Issue"
                subtitle = "Some networking error occured. Please try a different setup."
            case .unknownError:
                title = "Error"
                subtitle = "Unknown error occured. Please try a different setup."
            }
        }
        
        let managedError:ResponseError = ResponseError(title: title, details: subtitle)
        
        sender.send(Result.failure(managedError))
        
    }
    
    private func handleRequestFaulire(_ error: any Error) {
        self.handleConversionFailure(error)
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
    func convertValue(_ value:Double, fromCurrency:Currency, toCurrency:Currency) throws -> AnyPublisher<Result<Double, any Error>, Never> {
        
        guard fromCurrency != toCurrency else {
            throw CurrencyInputError.equalInputAndOutput
        }
        
        return self.convertValue(value, from: fromCurrency, to: toCurrency)
    }
}
