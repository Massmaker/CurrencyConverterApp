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
