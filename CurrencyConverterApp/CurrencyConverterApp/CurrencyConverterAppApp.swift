//
//  CurrencyConverterAppApp.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import SwiftUI

@main
struct CurrencyConverterAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: createContentViewModel())
        }
    }
    
    private func createContentViewModel() -> ContentViewModel {
        let apiRequestsBuilder = try! RequestBuilder(with: kBaseURLString) //this will fail early if some bad base url address is supplied
        let apiRequester = NetworkAPIService(with: apiRequestsBuilder)
        let interactor = ConverterInteractor(with: apiRequester)
        let vm = ContentViewModel(with: interactor, availableCurrencies: Currency.allCases)
        return vm
    }
}
