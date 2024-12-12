//
//  RequestBuilder.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//
import Foundation
protocol CurrenctRequestBuilding {
    func buildCurrencyExchangeRequestWith(input: any CurrencyConversionRequestInfo) throws -> URLRequest
}

class RequestBuilder: CurrenctRequestBuilding {
    
    private(set) var baseURLString:String
    
    enum HTTPMethods:String {
        case get, post, put, delete, head
        var httpMethodValue:String {
            self.rawValue.uppercased()
        }
    }
    
    init(with baseURLString:String) {
        self.baseURLString = baseURLString
    }
    
    func buildCurrencyExchangeRequestWith(input: any CurrencyConversionRequestInfo) throws -> URLRequest {
        guard let baseURL = URL(string: self.baseURLString) else {
            throw PreparationError.badURL
        }
        
        let sourceAmountValue = input.fromValue
        let sourceCurrencyParameter = input.fromCurrency.currencyAPIRequestParameterValue()
        let targetCurrencyParameter = input.toCurrency.currencyAPIRequestParameterValue()
        
        let path = "currency/commercial/exchange/\(sourceAmountValue)-\(sourceCurrencyParameter)/\(targetCurrencyParameter)/latest"
        
        let urlWithParams:URL = baseURL.appending(path: path)
        
        var urlGetRequest = URLRequest(url: urlWithParams)
        urlGetRequest.httpMethod = HTTPMethods.get.httpMethodValue
        urlGetRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return urlGetRequest
    }
}
