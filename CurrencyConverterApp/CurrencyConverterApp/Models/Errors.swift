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
    case badResponseFormat
    case badResponseCode(Int, AdditionalError?)
    case badURLResponse
    case networkingError(NetworkingError)
}

enum NetworkingError:Error {
    case requestTimeout
    case noInternetConnection
    case otherError
    case unknownError
}

enum CurrencyInputError : Error {
    case equalInputAndOutput
}


/**
    - Important: use JSONDecoder with keyDecodingStrategy .convertFromSnakeCase
 `
  {
      "error": "invalid_parameters",
      "error_description": "Can not parse amount or currency ABCDEFG"
  }
  `
 
*/
struct AdditionalError:Error {
    let error:String
    let errorDescription:String?
}

extension AdditionalError:Decodable {
    enum CodingKeys: CodingKey {
        case error
        case errorDescription
    }
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(String.self, forKey: .error)
        self.errorDescription = try container.decodeIfPresent(String.self, forKey: .errorDescription)
    }
}
