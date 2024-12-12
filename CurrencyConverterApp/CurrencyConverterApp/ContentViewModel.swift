//
//  ContentViewModel.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation
import Combine

fileprivate struct CurrencyRequestInfo: Equatable {
    private(set) var value:Double
    private(set) var input:Currency
    private(set) var output:Currency
    
    mutating func setValue(_ newValue:Double) {
        if self.value != newValue {
            self.value = newValue
        }
        
    }
    
    mutating func setInputCurrency(_ newInput:Currency) {
        if self.input != newInput {
            self.input = newInput
        }
    }
    
    mutating func setOutputCurrency(_ newOutput:Currency) {
        if self.output != newOutput {
            self.output = newOutput
        }
    }
}

extension Currency {
    var uiTitleRepresentation:String {
        self.rawValue.uppercased()
    }
}

class ContentViewModel:ObservableObject {
    
    private let refreshIntervalSeconds:Int = 10
    
    @Published var inProgress:Bool = false
    @Published var inputValueText:String = ""
    @Published var outputValueText:String = ""
    @Published var inputCurrencyTitle:String = ""
    @Published var outputCurrencyTitle:String = ""
    @Published private(set) var isCountdownActive:Bool = false
    
    @Published var isDisplayingAlert:Bool = false
    
    private(set) var alertInfo:AlertInfo?
    
    let interactor: any CurrencyConversionInteraction
    let currencies:[Currency]
    let currencyTitles:[String]
    
    private let requestInfoCVsubject:CurrentValueSubject<CurrencyRequestInfo, Never>
    
    private var lifetimeSubscriptions:Set<AnyCancellable> = []
    private var pendingSubscription:AnyCancellable?
    
    private var refreshTimer:Timer? {
        didSet {
            if let _ = refreshTimer {
                self.isCountdownActive = true
            }
            else {
                self.isCountdownActive = false
            }
        }
    }
    
    
    init(with conversionInteractor: any CurrencyConversionInteraction, availableCurrencies:[Currency]) {
        
        self.currencies = availableCurrencies
        self.currencyTitles = availableCurrencies.map {$0.uiTitleRepresentation}
        self.requestInfoCVsubject = CurrentValueSubject(CurrencyRequestInfo(value: 0.0,
                                                                            input: availableCurrencies.first ?? .usd,
                                                                            output: availableCurrencies.first ?? .usd))
        self.interactor = conversionInteractor
        
        conversionInteractor.isPendingRequest
            .receive(on: DispatchQueue.main)
            .assign(to: \.inProgress, on: self)
            .store(in: &lifetimeSubscriptions)
        
        
        
        if let firstCurrencyTitle = self.currencyTitles.first {
            self.inputCurrencyTitle = firstCurrencyTitle
            self.outputCurrencyTitle = firstCurrencyTitle
        }
        
        subscribeForValueTextChange()
        subscribeForInputCurrencyChange()
        subscribeForOutputCurrencyChange()
        subscribeForRequestInfoUpdates()
    }
    
    
    //MARK: - Timer
    private func startRefreshTimer() {
        let aTimer = Timer(timeInterval: TimeInterval(refreshIntervalSeconds), repeats: true, block: {[weak self] timer in
            guard let self else { return }
            
            self.requestCurrency()
        })
        
        self.refreshTimer = aTimer
        
        RunLoop.main.add(aTimer, forMode: .common)
        
    }
    
    private func stopRefreshTimer() {
        if let timer = self.refreshTimer, timer.isValid {
            timer.invalidate()
        }
        
        self.refreshTimer = nil
    }
    
    //MARK: - Errors
    private func displayAlertFor(_ alertInfo:AlertInfo) {
        self.alertInfo = alertInfo
        self.isDisplayingAlert = true
    }
    
    //MARK: -
    private func subscribeForValueTextChange() {
        $inputValueText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink {[unowned self] valueString in
                if let double = Double(valueString) {
                    var currentRequestInfo = self.requestInfoCVsubject.value
                    currentRequestInfo.setValue(double)
                    self.requestInfoCVsubject.send(currentRequestInfo)
                }
            }
            .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeForInputCurrencyChange() {
        self.$inputCurrencyTitle.sink {[unowned self] newInputTitle in
            if let newInput = Currency.createFromString(newInputTitle) {
                var currentRequestInfo = self.requestInfoCVsubject.value
                currentRequestInfo.setInputCurrency(newInput)
                self.requestInfoCVsubject.send(currentRequestInfo)
            }
        }
        .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeForOutputCurrencyChange() {
        self.$outputCurrencyTitle.sink {[unowned self] newOutputTitle in
            if let newOutput = Currency.createFromString(newOutputTitle) {
                var currentRequestInfo = self.requestInfoCVsubject.value
                currentRequestInfo.setOutputCurrency(newOutput)
                self.requestInfoCVsubject.send(currentRequestInfo)
            }
        }
        .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeForRequestInfoUpdates() {
        self.requestInfoCVsubject
            .drop(while: { aCurrencyRequestInfo in
                aCurrencyRequestInfo.input == aCurrencyRequestInfo.output
            })
            .removeDuplicates()
            .sink {[unowned self] aCurrencyRequestInfo in
                self.requestCurrency()
        }
        .store(in: &lifetimeSubscriptions)
    }
    
    //MARK: -
    private func requestCurrency() {
        
        let requestInfo = self.requestInfoCVsubject.value
        
        let value = requestInfo.value
        
        let fromCurrency = requestInfo.input
        
        let toCurrency = requestInfo.output
        
        self.stopRefreshTimer()
        
        do {
            let cancellable =
            try self.interactor.convertValue(value,
                                             fromCurrency: fromCurrency,
                                             toCurrency: toCurrency)
                .receive(on: DispatchQueue.main)
                .sink {[weak self] compl in
                    guard let self else { return }
                    if case .failure(let error) = compl {
                        self.handleConversionAttemptFailure(error)
                    }
                } receiveValue: { [weak self] result in
                    guard let self else { return }
                    
                    switch result {
                    case .success(let convertedValue):
                        self.handleConversionSuccess(convertedValue)
                    case .failure(let error):
                        self.handleConversionResultError(error)
                    }
                }
            
            self.pendingSubscription = cancellable
        }
        catch {
            if let currencyInputError = error as? CurrencyInputError {
                switch currencyInputError {
                case .equalInputAndOutput:
                    self.alertInfo = AlertInfo(title: "Error", subtitle: "Currencies must be different", actions: [AlertAction(title: "Ok", action: {}, emphasized: false, destructive: false)])
                    self.isDisplayingAlert = true
                }
            }
            else {
                //handle other errors
                self.alertInfo = AlertInfo(title: "Error", subtitle: error.localizedDescription, actions: [AlertAction(title: "Close", action: {}, emphasized: false, destructive: false)])
                self.isDisplayingAlert = true
            }
        }
    }
    
    //MARK: -
    private func handleConversionSuccess(_ result:Double) {
        defer {
            self.startRefreshTimer()
        }
        self.outputValueText = String(result)
        self.removePendingSubscription()
        
    }
    
    
    //MARK: - Error Handling
    private func handleConversionAttemptFailure(_ error: any Error) {
        
        defer {
            self.removePendingSubscription()
        }
       
        guard let somePrimitiveError = error as? PrimitiveErrorType else {
            self.displayAlertFor(AlertInfo.defaultAlert(with: "Unknown error"))
            return
        }
        
        self.displayAlertFor(AlertInfo(title: somePrimitiveError.title,
                                       subtitle: somePrimitiveError.details ?? "",
                                       actions: [AlertAction.defaultCancelAction()]))
    }
    
    private func handleConversionResultError(_ error: any Error) {
        defer {
            self.removePendingSubscription()
            self.stopRefreshTimer()
        }
        
        guard let somePrimitiveError = error as? PrimitiveErrorType else {
            self.displayAlertFor(AlertInfo.defaultAlert(with: "Unknown error"))
            return
        }
        
        self.displayAlertFor(AlertInfo(title: somePrimitiveError.title,
                                       subtitle: somePrimitiveError.details ?? "",
                                       actions: [AlertAction(title: "Close", action: {}, emphasized: false, destructive: false)]))
    }
    
    //MARK: -
    private func removePendingSubscription() {
        self.pendingSubscription?.cancel()
        self.pendingSubscription = nil
    }
}
