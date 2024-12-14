//
//  ContentView.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel:ContentViewModel
    @FocusState private var isTextVieldFocused:Bool
    @State private var isWheelPickerStyle: Bool = false
    
    //handling the small iPhone rotation
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
     
    
    var body: some View {
        if viewModel.isUIKit {
            uiKit_ui
        }
        else {
            swiftUI_ui
        }
    }
    
    @ViewBuilder private var uiKit_ui: some View {
        UIKitPresentingView(with: WeakObject(self.viewModel),
                            switcher: WeakObject(self.viewModel))
    }
    
    @ViewBuilder private var swiftUI_ui: some View {
        VStack{
            if verticalSizeClass == .compact && horizontalSizeClass == .compact {
                smallIphoneHorizontalUI
            }
            else if horizontalSizeClass == .compact {
                iphoneVerticalUI
                
            }
            else {
                defaultUI
            }
            
        }
        .background(LinearGradient(colors: [Color.clear, .accentColor], startPoint: .top, endPoint: .bottom))
        .overlay(alignment: .bottomLeading, content: {
            HStack{
                Button(action: viewModel.uiActionToggleUI, label: {Text(viewModel.toggleUIActionName)})
                    .foregroundStyle(.tertiary)
            }
            .padding()
        })
        .alert(viewModel.alertInfo?.title ?? "Error",
               isPresented: $viewModel.isDisplayingAlert,
               presenting: viewModel.alertInfo,
               actions: { alertInfo in
            ForEach(alertInfo.actions) { action in
                action.body
            }
        },
               message: {alertInfo in
            Text(alertInfo.subtitle ?? "")
        })
    }
    
    @ViewBuilder private var smallIphoneHorizontalUI: some View {
        VStack {
            HStack {
                if !viewModel.backwardConversion {
                    Spacer()
                    textField
                }
                else {
                    valueLabel
                }
                
                Picker("From", selection: $viewModel.inputCurrencyTitle) {
                    ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                        Text(currencyTitle)
                    })
                }
                
                toggleDirectionButton
                
                
                Picker("To", selection: $viewModel.outputCurrencyTitle) {
                    ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                        Text(currencyTitle)
                    })
                }
                .font(.largeTitle)
                
                if viewModel.backwardConversion {
                    textField
                    Spacer()
                }
                else {
                    valueLabel
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        
        
    }
    
    @ViewBuilder private var iphoneVerticalUI: some View {
        VStack {
            
            
            VStack (spacing:24) {
                HStack {
                    if isWheelPickerStyle {
                        Picker("From", selection: $viewModel.inputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                if viewModel.backwardConversion {
                                    Text(currencyTitle)
                                        .font(.largeTitle)
                                }
                                else {
                                    Text(currencyTitle)
                                }
                            })
                        }
                        .pickerStyle(.wheel)
                    }
                    else {
                        Picker("From", selection: $viewModel.inputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
                            })
                        }
                    }
                    
                    
                    toggleDirectionButton
                    
                    
                    if isWheelPickerStyle {
                        Picker("To", selection: $viewModel.outputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                if viewModel.backwardConversion {
                                    Text(currencyTitle)
                                }
                                else {
                                    Text(currencyTitle)
                                        .font(.largeTitle)
                                }
                            })
                        }
                        .pickerStyle( .wheel)
                        
                    }
                    else {
                        Picker("To", selection: $viewModel.outputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
                            })
                        }
                        .font(.largeTitle)
                        
                    }
                    
                }
                
                HStack {
                    Spacer()
                    textField
                    Spacer()
                    
                    
                }
                
                
                valueLabel
                
            }
            
            Spacer()
            
            HStack {
                Text("Wheel Style pickers")
                    .foregroundStyle(.secondary)
                
                Toggle("", isOn: $isWheelPickerStyle)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
            
//            Spacer()
        }
        
    }
    
    @ViewBuilder private var defaultUI: some View {
        VStack {
            
            HStack {
                Text("Wheel Style pickers")
                    .foregroundStyle(.secondary)
                
                Toggle("", isOn: $isWheelPickerStyle)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            .padding(.horizontal)
            
            VStack (spacing:24) {
                HStack {
                    if isWheelPickerStyle {
                        Picker("From", selection: $viewModel.inputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                if viewModel.backwardConversion {
                                    Text(currencyTitle)
                                        .font(.largeTitle)
                                }
                                else {
                                    Text(currencyTitle)
                                }
                            })
                        }
                        .pickerStyle(.wheel)
                    }
                    else {
                        Picker("From", selection: $viewModel.inputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
                            })
                        }
                    }
                   

                    toggleDirectionButton
                    
                    
                    if isWheelPickerStyle {
                        Picker("To", selection: $viewModel.outputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                if viewModel.backwardConversion {
                                    Text(currencyTitle)
                                }
                                else {
                                    Text(currencyTitle)
                                        .font(.largeTitle)
                                }
                            })
                        }
                        .pickerStyle( .wheel)
                        
                    }
                    else {
                        Picker("To", selection: $viewModel.outputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
                            })
                        }
                        .font(.largeTitle)
                        
                    }
                        
                }
                
                HStack {
                    Spacer()
                    if viewModel.backwardConversion {
                        HStack {
                            Text(viewModel.outputValueText)
                                .font(.title)
                        }
                        Spacer()
                    }
                    
                    textField
                    
                    if !viewModel.backwardConversion {

                        Spacer()
                            HStack {
                            
                                Text(viewModel.outputValueText)
                                    .font(.title)
                            }
                    }
                    Spacer()
                    
                    
                }
                
                
            }
            Spacer()
        }
        
    }
    
    @ViewBuilder private var toggleDirectionButton: some View {
        
        Button(action: viewModel.uiActionToggleConversionDirection, label: {
            if #available(iOS 18.0, *) {
                Text(Image(systemName: viewModel.toggleConversionIconName))
                    .fontWeight(.bold)
                    .symbolEffect(viewModel.backwardConversion ? .rotate.counterClockwise : .rotate.clockwise)
                    .padding()
            } else if #available(iOS 17.0, *) {
                
                Text(Image(systemName: viewModel.toggleConversionIconName))
                    .fontWeight(.bold)
                    .symbolEffect(.pulse)
                    .padding()
            }
            else {
                Text(Image(systemName: viewModel.toggleConversionIconName))
                    .fontWeight(.bold)
                    .padding()
            }
        })
        .fontWeight(.bold)
    }
    
    @ViewBuilder private var textField: some View {
        TextField("Input Value", text: $viewModel.inputValueText, prompt: Text("Enter a Value"))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numbersAndPunctuation)
            .font(.title)
            .focused($isTextVieldFocused)
            .frame(maxWidth: 260)
            .overlay(alignment: .trailing, content: {
                if viewModel.isCountdownActive {
                    if #available(iOS 17.0, *) {
                        if #available(iOS 18.0, *) {
                            
                            Image(systemName: "10.arrow.trianglehead.counterclockwise")
                                .resizable()
                                .frame(width:30, height:30)
                                .foregroundStyle(Color.mint)
                                .symbolEffect(.bounce, options: .repeat(SymbolEffectOptions.RepeatBehavior.periodic(1,delay: 2)))
                            
                            
                        } else {
                            Image(systemName: "timer")
                                .resizable()
                                .frame(width:34, height:34)
                                .symbolEffect(.pulse)
                        }
                    } else {
                        // Fallback on earlier versions
                        Image(systemName: "timer")
                    }
                }
                else if viewModel.inProgress {
                    if #available(iOS 18.0, *) {
                        Image(systemName: "progress.indicator")
                            .resizable()
                            .frame(width:30, height:30)
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.rotate.counterClockwise.byLayer, options: .repeat(SymbolEffectOptions.RepeatBehavior.continuous))
                    } else {
                        // Fallback on earlier versions
                        ProgressView()//"Please wait...")
                            .progressViewStyle(.circular)
                    }
                }
            })
    }
    
    @ViewBuilder private var valueLabel: some View {
        Text(viewModel.outputValueText.isEmpty ? "  " : viewModel.outputValueText)
                .font(.title)
                .padding(8)
                .frame(minWidth: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.accent, lineWidth: 2)
                    )
    }
}

#Preview {
    ContentView(viewModel: ContentViewModel(with: CurrencyConversionInteractorDummy(),
                                            availableCurrencies: Currency.allCases))
}



