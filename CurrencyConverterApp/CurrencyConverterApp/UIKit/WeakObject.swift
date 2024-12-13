//
//  WeakObject.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import Foundation

class WeakObject<T:AnyObject> {
    weak var object:T?
    
    init(_ object: T) {
        self.object = object
    }
}

import UIKit
extension WeakObject:UIKitPickerSelectionReceiver where T:UIKitPickerSelectionReceiver {
    func receiveSelectedCurrencyName(_ name: String, fromPicker picker: UIPickerView) {
        object?.receiveSelectedCurrencyName(name, fromPicker: picker)
    }
}

extension WeakObject:CurrencyFromValueChangeReceiving where T:CurrencyFromValueChangeReceiving {
    func receiveCurrencyValueText(_ string: String) {
        object?.receiveCurrencyValueText(string)
    }
}

extension WeakObject:UXUIFrameworkSwitching where T:UXUIFrameworkSwitching {
    func switchToUIKit() {
        object?.switchToUIKit()
    }
    
    func switchToSwiftUI() {
        object?.switchToSwiftUI()
    }
}

import Combine
extension WeakObject:ContentViewModelType where T:ContentViewModelType {
    var currencyTitles: [String] {
        object?.currencyTitles ?? []
    }
    
    var toggleConversionIconNamePublisher: AnyPublisher<String, Never> {
        object?.toggleConversionIconNamePublisher ?? Empty().eraseToAnyPublisher()
    }
    
    var backwardConversionPublisher: AnyPublisher<Bool, Never> {
        object?.backwardConversionPublisher ?? Empty().eraseToAnyPublisher()
    }
    
    var outputValueTextPublisher: AnyPublisher<String, Never> {
        object?.outputValueTextPublisher ?? Empty().eraseToAnyPublisher()
    }
    
    var isAlertPublisher: AnyPublisher<Bool, Never> {
        object?.isAlertPublisher ?? Empty().eraseToAnyPublisher()
    }
    
    var alertInfoData: AlertInfo? {
        object?.alertInfoData
    }
    
    var inputText: String? {
        object?.inputText
    }
    
    func uiActionToggleConversionDirection() {
        object?.uiActionToggleConversionDirection()
    }
    
    func setInputCurrencyName(_ string: String) {
        object?.setInputCurrencyName(string)
    }
    
    func setOutputCurrencyName(_ string: String) {
        object?.setOutputCurrencyName(string)
    }
    
    func setInputValueText(_ string: String) {
        object?.setInputValueText(string)
    }
    
}
