//
//  ContentView.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel:ContentViewModel
    
    var body: some View {
        VStack {
            Spacer()
            VStack (spacing:24) {
                HStack {
                    
                    Picker("From", selection: $viewModel.inputCurrencyTitle) {
                        ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                            Text(currencyTitle)
                        })
                    }
                    
                    Text(Image(systemName: "arrow.right"))
                        .fontWeight(.bold)
                        .padding()
                    
                    Picker("To", selection: $viewModel.outputCurrencyTitle) {
                        ForEach(viewModel.currencyTitles, id: \.self, content: {currencyTitle in
                            Text(currencyTitle)
                        })
                    }
                }
                
                HStack {
                    Spacer()
                    TextField("Input Value", text: $viewModel.inputValueText, prompt: Text("Enter a Value"))
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .font(.title)
                        .frame(maxWidth: 260)
                        .onSubmit {
                            
                        }
                    Spacer()
                }
                
                Text(viewModel.outputValueText)
            }
            Spacer()
        }
        .background(LinearGradient(colors: [Color.gray.opacity(0.5), .green.opacity(0.7), .gray], startPoint: .top, endPoint: .bottom))
        .disabled(viewModel.inProgress)
        .overlay {
            if viewModel.inProgress {
                ProgressView("Please wait...")
                    .progressViewStyle(.circular)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .circular))
            }
        }
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
