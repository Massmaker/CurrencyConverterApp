//
//  UIKitPresentingView.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import SwiftUI

struct UIKitPresentingView: UIViewControllerRepresentable {
   
    typealias UIViewControllerType = CurrencyViewController
    
    let viewModel:ContentViewModel
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIViewController(context: Context) -> CurrencyViewController {
        CurrencyViewController(viewModel: self.viewModel)
    }
    
    func updateUIViewController(_ uiViewController: CurrencyViewController, context: Context) {
        
    }
    
   
    
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
}

#Preview {
    UIKitPresentingView(viewModel: ContentViewModel.init(with: CurrencyConversionInteractorDummy(), availableCurrencies: Currency.allCases))
}
