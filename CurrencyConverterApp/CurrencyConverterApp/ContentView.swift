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
    
    var body: some View {
        VStack {
            
            HStack {
                Text("Wheel Style pickers")
                Toggle("", isOn: $isWheelPickerStyle)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            
            VStack (spacing:24) {
                HStack {
                    if isWheelPickerStyle {
                        Picker("From", selection: $viewModel.inputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
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
                    .buttonStyle(.bordered)
                    
                    
                    
                    if isWheelPickerStyle {
                        Picker("To", selection: $viewModel.outputCurrencyTitle) {
                            ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                                Text(currencyTitle)
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
                    }
                        
                }
                
                HStack {
                    Spacer()
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
                                            .frame(width:34, height:34)
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
                                        .frame(width:34, height:34)
                                        .foregroundStyle(Color.accentColor)
                                        .symbolEffect(.rotate.counterClockwise.byLayer, options: .repeat(SymbolEffectOptions.RepeatBehavior.continuous))
                                } else {
                                    // Fallback on earlier versions
                                    ProgressView()//"Please wait...")
                                        .progressViewStyle(.circular)
                                }
                            }
                        })
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
            Spacer()
        }
        .background(LinearGradient(colors: [Color.gray.opacity(0.5), .green.opacity(0.7), .gray], startPoint: .top, endPoint: .bottom))
        .disabled(viewModel.inProgress)
//        .overlay {
//            if viewModel.inProgress {
//                ProgressView("Please wait...")
//                    .progressViewStyle(.circular)
//                    .padding()
//                    .background(.ultraThinMaterial)
//                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .circular))
//            }
//        }
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
}

#Preview {
    ContentView(viewModel: ContentViewModel(with: CurrencyConversionInteractorDummy(),
                                            availableCurrencies: Currency.allCases))
}



