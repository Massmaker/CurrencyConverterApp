//
//  RequestBuilder.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//
import Foundation
protocol CurrencyRequestBuilding {
    func buildCurrencyExchangeRequestWith(input: any CurrencyConversionRequestInfo) -> URLRequest
}

let kBaseURLString:String = "http://api.evp.lt"

class RequestBuilder: CurrencyRequestBuilding {
    
    private(set) var baseURL:URL
    
    enum HTTPMethods:String {
        case get, post, put, delete, head
        var httpMethodValue:String {
            self.rawValue.uppercased()
        }
    }
    
    init(with baseURLString:String) throws {
        
        guard let baseURL = URL(string: baseURLString) else {
            throw PreparationError.badURL
        }
        self.baseURL = baseURL
    }
    
    func buildCurrencyExchangeRequestWith(input: any CurrencyConversionRequestInfo) -> URLRequest {
        
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
