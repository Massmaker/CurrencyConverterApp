//
//  NetworkAPIService.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation
import Combine

//Request
/* http://api.evp.lt/currency/commercial/exchange/{fromAmount}-{fromCurrency}/{toCurrency}/latest */
//Result
/* {"amount":"54521","currency":"JPY"}*/

protocol CurrencyAPIRequestParameterValueConvertible {
    func currencyAPIRequestParameterValue() -> String
}

protocol CurrencyConversionRequestInfo {
    var fromValue:Double {get}
    var fromCurrency:Currency {get}
    var toCurrency:Currency {get}
}

protocol CurrencyConversionResult {
    var currency:Currency {get}
    var value:Double {get}
}

protocol CurrencyConversion {
    func getConversion(for conversionRequest: any CurrencyConversionRequestInfo) -> AnyPublisher<Result<CurrencyConversionResult, Error>, Error>
}

class NetworkAPIService {
    private let urlRequestsBuilder: any CurrencyRequestBuilding
       
    private var session:URLSession
    
    private lazy var urlRequestSubscriptions:[UUID:AnyCancellable] = [:]
    private lazy var resultSubjects:[UUID:PassthroughSubject<Result<any CurrencyConversionResult, any Error>, any Error>] = [:]
    
    init(with requestsBuider: any CurrencyRequestBuilding) {
        self.urlRequestsBuilder = requestsBuider
        self.session = URLSession(configuration: .default)
    }
    
    deinit {
        resultSubjects.removeAll()
        urlRequestSubscriptions.values.forEach({$0.cancel()})
        session.invalidateAndCancel()
    }
}

extension NetworkAPIService: CurrencyConversion {
    struct CurrencyConversionInfo:CurrencyConversionResult {
        let currency:Currency
        let value:Double
    }
    
    func getConversion(for conversionRequest: any CurrencyConversionRequestInfo) -> AnyPublisher<Result<any CurrencyConversionResult, any Error>, any Error> {
        
        if !self.urlRequestSubscriptions.isEmpty {
            self.urlRequestSubscriptions.forEach { (key: UUID, _ ) in
                self.finishSubscriptionFor(uid: key)
            }
        }
        
        
        let urlRequest = self.urlRequestsBuilder.buildCurrencyExchangeRequestWith(input: conversionRequest)
        
        let passTrough:PassthroughSubject<Result<any CurrencyConversionResult, any Error>, any Error> = .init()
        
        let uid = UUID()
        let cancellable =
        self.session.dataTaskPublisher(for: urlRequest)
            .sink {[weak self, uid] completion in
            guard let self else {
                return
            }
            
            if case .failure(let error) = completion {
                self.handleResponseFailure(error, forUID: uid)
            }
            
        } receiveValue: {[weak self, uid] response  in
            guard let self else {
                return
            }
            self.handleURLResponse(response, forUID: uid)
        }
        
        //store to be able to cancel the ongoing request
        self.urlRequestSubscriptions[uid] = cancellable //thread unsafe. better would be using a separate queue for managing the subscriptions dict or use an "actor"
        self.resultSubjects[uid] = passTrough
        
        return passTrough.eraseToAnyPublisher()

    }
    
    /// finds response callback subject and sends `.success` or `.failure` results containing a Double value or CurrencyResponseFailure in case of some errors
    private func handleURLResponse(_ response:(Data,URLResponse), forUID uid:UUID) {
        defer {
            finishSubscriptionFor(uid: uid)
        }
        
        guard let resultSender = self.resultSubjects[uid] else {
            return
        }
        
        
        if let currencyResponseFailure = self.handledBadResponse(response) {
            resultSender.send(Result.failure(currencyResponseFailure))
            return
        }
      
        
        let data = response.0
        
        guard !data.isEmpty else {
            resultSender.send(Result.failure(CurrencyResponseFailure.badResponseData))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            
            let response:CurrencyConversionResponse = try decoder.decode(CurrencyConversionResponse.self, from: data)
            
            guard let aCurrency = Currency.createFromString(response.currency) else {
                resultSender.send(Result.failure(CurrencyResponseFailure.badResponseFormat))
                return
            }
            
            let result = CurrencyConversionInfo(currency: aCurrency, value: response.value)
            
            resultSender.send(Result.success(result))
        }
        catch {
            //Decoding of the response failed
            resultSender.send(Result.failure(CurrencyResponseFailure.badResponseFormat))
        }
        
        
    }
    
    /// sends a `CurrencyResponseFailure.networkingError` with  `NetworkingError` inside if the resultSubject is found in `resultSubjects`
    private func handleResponseFailure(_ anyError: any Error, forUID uid:UUID) {
        defer {
            finishSubscriptionFor(uid: uid)
        }
        
        guard let resultSender = self.resultSubjects[uid] else {
            return
        }
        
        guard let urlError = anyError as? URLError else {
            resultSender.send(.failure(CurrencyResponseFailure.networkingError(NetworkingError.unknownError)))
            return
        }
        
        let anError:NetworkingError
        
        switch urlError.code {
        case .timedOut:
            anError = .requestTimeout
        case .notConnectedToInternet:
            anError = .noInternetConnection
        default:
            anError = .otherError
        }
        //appTransportSecurityRequiresSecureConnection: -1022
        
        resultSender.send(.failure(CurrencyResponseFailure.networkingError(anError)))
    }
    
    
    private func handledBadResponse(_ response:(Data,URLResponse)) -> CurrencyResponseFailure? {
        
        let urlResponse = response.1
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            return CurrencyResponseFailure.badURLResponse
        }
        
        let statusCode = httpResponse.statusCode
        guard statusCode >= 200, statusCode < 300 else {
            
            let responseData = response.0
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let detailedError = try? decoder.decode(AdditionalError.self, from: responseData) {
                return CurrencyResponseFailure.badResponseCode(statusCode, detailedError)
            }
            else {
                return CurrencyResponseFailure.badResponseCode(statusCode, nil)
            }
        }
        
        return nil
    }
    
    private func finishSubscriptionFor(uid:UUID) {
        self.urlRequestSubscriptions[uid]?.cancel()
        self.urlRequestSubscriptions[uid] = nil
        self.resultSubjects[uid] = nil
    }
}
