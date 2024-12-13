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
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        if string.isEmpty, let text = textField.text as? NSString {
            let newString = text.replacingCharacters(in: range, with: "")
            self.textChangeReceiver.receiveCurrencyValueText(newString)
        }
        else if let text = textField.text as? NSString {
            let newString = text.replacingCharacters(in: range, with: string)
            self.textChangeReceiver.receiveCurrencyValueText(newString)
        }
        
        return true
    }
}
