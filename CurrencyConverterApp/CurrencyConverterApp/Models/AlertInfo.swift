//
//  AlertInfo.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation

struct AlertInfo {
    let title:String
    var subtitle:String?
    var actions:[AlertAction]
}

struct AlertAction {
    let title:String
    let action: ()->()
    var emphasized:Bool //bold or not bold title, probably for the "default extected" actions
    var destructive:Bool //red text color, to make some extra confirmations if needed
    
    init(title: String, action: @escaping () -> Void, emphasized: Bool, destructive: Bool) {
        self.title = title
        self.action = action
        self.emphasized = emphasized
        self.destructive = destructive
    }
}

extension AlertAction {
    /// an AlertAction with `OK` title, non-emphasized, non-destructive
    static func defaultCancelAction() -> AlertAction{
        return AlertAction(title: "Ok", action: {}, emphasized: false, destructive: false)
    }
}


extension AlertInfo {
    static func defaultAlert(with title:String, details:String = "") -> AlertInfo {
        return AlertInfo(title: title,
                         subtitle: details.isEmpty ? nil : details,
                         actions: [.defaultCancelAction()])
    }
}

import SwiftUI
extension AlertAction: View {
    var body: some View {
        
        if self.emphasized {
            Button(role: self.destructive ? .destructive : nil, action: self.action, label: { Text(title) })
                .keyboardShortcut(.defaultAction)
        }
        else {
            Button(role: self.destructive ? .destructive : nil, action: self.action, label: { Text(title) })
        }
    }
}


extension AlertAction:Identifiable {
    var id:String {
        return "AlertAction_\(title)_emphasized-\(emphasized ? "true" : "false")_destrictive-\(destructive ? "true" : "false")"
    }
}
