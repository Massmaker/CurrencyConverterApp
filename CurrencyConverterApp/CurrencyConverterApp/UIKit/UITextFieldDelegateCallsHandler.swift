//
//  UITextFieldDelegateCallsHandler.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import Foundation
import UIKit

protocol CurrencyFromValueChangeReceiving {
    func receiveCurrencyValueText(_ string:String)
}

class UITextFieldDelegateCallsHandler:NSObject, UITextFieldDelegate {
    
    let textChangeReceiver: any CurrencyFromValueChangeReceiving
    
    init(textChangeReceiver: any CurrencyFromValueChangeReceiving) {
        self.textChangeReceiver = textChangeReceiver
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        defer {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.textChangeReceiver.receiveCurrencyValueText(string)
        
        return true
    }
}
