//
//  UIAlertController+Extensions.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//


import UIKit
extension UIAlertController {
    class func createWith(_ alertInfo:AlertInfo) -> UIAlertController {
        
        let alertController = UIAlertController(title: alertInfo.title, message: alertInfo.subtitle, preferredStyle: .alert)
        
        guard  !alertInfo.actions.isEmpty else  {
            return alertController
        }
        
        alertInfo.actions.forEach { action in
            
            let alertActionStyle:UIAlertAction.Style
            
            if action.destructive {
                alertActionStyle = .destructive
            }
            else {
                alertActionStyle = .default
            }
            
            let alertAction =  UIAlertAction(title: action.title, style: alertActionStyle, handler: {[action] one in
                action.action()
            })
            
            alertController.addAction(alertAction)
            
            if action.emphasized {
                alertController.preferredAction = alertAction
            }
        }
        
        return alertController
    }
}
