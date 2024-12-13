//
//  UIPickerDataSource.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import Foundation
import UIKit

class UIPickerDataSource:NSObject, UIPickerViewDataSource  {
    
    let currencyTitles:[String]
    
    init(currencyTitles: [String]) {
        self.currencyTitles = currencyTitles
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyTitles.count
    }
}
