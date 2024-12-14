//
//  UIKitPresentingView.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import SwiftUI

struct UIKitPresentingView: UIViewControllerRepresentable {
   
    typealias UIViewControllerType = CurrencyViewController
    
    let anyViewModel: any ContentViewModelType
    let switcher: any UXUIFrameworkSwitching
    
    init(with viewModel: any ContentViewModelType, switcher: any UXUIFrameworkSwitching) {
        self.anyViewModel = viewModel
        self.switcher = switcher
    }
    
    func makeUIViewController(context: Context) -> CurrencyViewController {
        CurrencyViewController(viewModel: self.anyViewModel, uxUiSwitcher: self.switcher)
    }
    
    func updateUIViewController(_ uiViewController: CurrencyViewController, context: Context) {
        
    }
    
   
    
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
}

#Preview {
    let dummyVM = ContentViewModel.init(with: CurrencyConversionInteractorDummy(), availableCurrencies: Currency.allCases)
    UIKitPresentingView(with: dummyVM, switcher: dummyVM)
}
