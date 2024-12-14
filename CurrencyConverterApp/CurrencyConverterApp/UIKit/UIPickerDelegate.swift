//
//  UIPickerDelegate.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import Foundation
import UIKit


protocol UIKitPickerSelectionReceiver {
    func receiveSelectedCurrencyName(_ name:String, fromPicker picker:UIPickerView)
}

class UIPickerDelegate: NSObject, UIPickerViewDelegate {
    let currencyTitles:[String]
    let selectionReceiver: any UIKitPickerSelectionReceiver
    
    init(currencyTitles: [String], selectionReceiver receiver: any UIKitPickerSelectionReceiver) {
        self.currencyTitles = currencyTitles
        self.selectionReceiver = receiver
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencyTitles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.selectionReceiver.receiveSelectedCurrencyName(currencyTitles[row], fromPicker: pickerView)
    }

}
