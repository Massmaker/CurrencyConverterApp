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
     
        VStack{
            if verticalSizeClass == .compact && horizontalSizeClass == .compact {
                smallIphoneHorizontalUI
            }
            else if horizontalSizeClass == .compact {
                iphoneVerticalUI
                Spacer()
            }
            else {
                defaultUI
            }
            
        }
        .background(LinearGradient(colors: [Color.clear, .accentColor], startPoint: .top, endPoint: .bottom))
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

        HStack {
            if !viewModel.backwardConversion {
                textField
            }
            else {
                if !viewModel.outputValueText.isEmpty {
                    
                        Text(viewModel.outputValueText)
                            .font(.title)
                            .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.accent, lineWidth: 2)
                                )
                    
                }
            }
            
            Picker("From", selection: $viewModel.inputCurrencyTitle) {
                ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                    Text(currencyTitle)
                })
            }
            
            Button(action: viewModel.uiActionToggleConversionDirection, label: {
                if #available(iOS 18.0, *) {
                    Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                        .fontWeight(.bold)
                        .symbolEffect(viewModel.backwardConversion ? .rotate.counterClockwise : .rotate.clockwise)
                        .padding()
                } else if #available(iOS 17.0, *) {
                    
                    Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                        .fontWeight(.bold)
                        .symbolEffect(.pulse)
                        .padding()
                }
                else {
                    Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                        .fontWeight(.bold)
                        .padding()
                }
            })
            //.buttonStyle(.bordered)
            .fontWeight(.bold)
            
            
            
            Picker("To", selection: $viewModel.outputCurrencyTitle) {
                ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                    Text(currencyTitle)
                })
            }
            .font(.largeTitle)
            
            if viewModel.backwardConversion {
                textField
            }
            else {
                if !viewModel.outputValueText.isEmpty {
                    
                        Text(viewModel.outputValueText)
                            .font(.title)
                            .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.accent, lineWidth: 2)
                                )
                    
                }
            }
        }
    }
    
    @ViewBuilder private var iphoneVerticalUI: some View {
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
                
                
                Button(action: viewModel.uiActionToggleConversionDirection, label: {
                    if #available(iOS 18.0, *) {
                        Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                            .fontWeight(.bold)
                            .symbolEffect(viewModel.backwardConversion ? .rotate.counterClockwise : .rotate.clockwise)
                            .padding()
                    } else if #available(iOS 17.0, *) {
                        
                        Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                            .fontWeight(.bold)
                            .symbolEffect(.pulse)
                            .padding()
                    }
                    else {
                        Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                            .fontWeight(.bold)
                            .padding()
                    }
                })
                //.buttonStyle(.bordered)
                .fontWeight(.bold)
                
                
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
            
            if !viewModel.outputValueText.isEmpty {
                HStack {
                    Text("Result:")
                        .font(.subheadline)
                    
                    Text(viewModel.outputValueText)
                        .font(.title)
                }
            }
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
                   
                    
                    Button(action: viewModel.uiActionToggleConversionDirection, label: {
                        if #available(iOS 18.0, *) {
                            Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                                .fontWeight(.bold)
                                .symbolEffect(viewModel.backwardConversion ? .rotate.counterClockwise : .rotate.clockwise)
                                .padding()
                        } else if #available(iOS 17.0, *) {
                            
                            Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                                .fontWeight(.bold)
                                .symbolEffect(.pulse)
                                .padding()
                        }
                        else {
                            Text(Image(systemName: viewModel.backwardConversion ? "arrow.left" : "arrow.right"))
                                .fontWeight(.bold)
                                .padding()
                        }
                    })
                    //.buttonStyle(.bordered)
                    .fontWeight(.bold)
                    
                    
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
    
    @ViewBuilder private var textField: some View {
        TextField("Input Value", text: $viewModel.inputValueText, prompt: Text("Enter a Value"))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
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
}

#Preview {
    ContentView(viewModel: ContentViewModel(with: CurrencyConversionInteractorDummy(),
                                            availableCurrencies: Currency.allCases))
}



