//
//  ContentViewModel.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation
import Combine
import SwiftUI

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
    
    @Published var isUIKit:Bool = false
    @Published private(set) var toggleUIActionName:String = kToUIKitActionName
    
    @Published var inProgress:Bool = false
    @Published var inputValueText:String = ""
    @Published var outputValueText:String = ""
    @Published var inputCurrencyTitle:String = ""
    @Published var outputCurrencyTitle:String = ""
    @Published private(set) var isCountdownActive:Bool = false
    
    @Published private(set) var backwardConversion:Bool = false
    @Published private(set) var toggleConversionIconName:String = kArrowRightName
    
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
//            .assign(to: \.inProgress, on: self)
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: {[unowned self] isPending in
                if self.inProgress && !isPending {
//                    withAnimation(.easeIn(duration: 0.3).delay(1.0)) {
                        self.inProgress = isPending
//                    }
                }
                else if !self.inProgress && isPending {
//                    withAnimation{
                        self.inProgress = isPending
//                    }
                    
                }
            })
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
    
    deinit {
        stopRefreshTimer()
    }
    
    func uiActionToggleConversionDirection() {
        withAnimation {
            self.backwardConversion.toggle()
            self.toggleConversionIconName = self.backwardConversion ? kArrowLeftName : kArrowRightName
        }
        
        self.requestCurrency()
    }
    
    func uiActionToggleUI() {
        withAnimation {
            self.isUIKit.toggle()
            
        }
        if self.isUIKit {
            self.toggleUIActionName = kToSwiftUIActionName
        }
        else {
            self.toggleUIActionName = kToUIKitActionName
        }
    }
    
    //MARK: - Timer
    private func startRefreshTimer() {
        
        guard self.refreshTimer == nil else {
            return
        }
        
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
            .debounce(for: .milliseconds(1300), scheduler: DispatchQueue.main)
            .sink {[unowned self] valueString in
                
                if let double = Double(valueString) {
                    var currentRequestInfo = self.requestInfoCVsubject.value
                    currentRequestInfo.setValue(double)
                    self.requestInfoCVsubject.send(currentRequestInfo)
                }
                else {
                    self.stopRefreshTimer()
                    var currentRequestInfo = self.requestInfoCVsubject.value
                    currentRequestInfo.setValue(0)
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
                
                let isNotGreaterThanZero = !(aCurrencyRequestInfo.value > 0)
                return isNotGreaterThanZero
            })
            .drop(while: { aCurrencyInfo in
                aCurrencyInfo.input == aCurrencyInfo.output
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
        
        let fromCurrency = self.backwardConversion ? requestInfo.output : requestInfo.input
        
        let toCurrency = self.backwardConversion ? requestInfo.input : requestInfo.output
        
        self.stopRefreshTimer()
        
        guard toCurrency != fromCurrency else {
//            self.inputValueText = ""
            self.outputValueText = ""
            return
        }
        
        guard value > 0 else {
            self.outputValueText = ""
            return
        }
        
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
        
        
        self.outputValueText = result.formatted(.currency(code: self.backwardConversion ? self.inputCurrencyTitle : self.outputCurrencyTitle ))
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


//MARK: - ContentViewModelType
extension ContentViewModel: ContentViewModelType {
    var inputCurrencyName: String? {
        self.inputCurrencyTitle
    }
    
    var outputCurrencyName: String? {
        self.outputCurrencyTitle
    }
    
    var isFetchingConversionDataPublisher: AnyPublisher<Bool, Never> {
        self.$inProgress.eraseToAnyPublisher()
    }
    
    var toggleConversionIconNamePublisher: AnyPublisher<String, Never> {
        self.$toggleConversionIconName.eraseToAnyPublisher()
    }
    
    var isOppositeDirectionConversionPublisher: AnyPublisher<Bool, Never> {
        self.$backwardConversion.eraseToAnyPublisher()
    }
    
    var outputValueTextPublisher: AnyPublisher<String, Never> {
        self.$outputValueText.eraseToAnyPublisher()
    }
    
    var inputText:String? {
        self.inputValueText
    }
    
    var isAlertPublisher:AnyPublisher<Bool, Never> {
        self.$isDisplayingAlert.eraseToAnyPublisher()
    }
    
    var alertInfoData: AlertInfo? {
        self.alertInfo
    }
    
    func setInputCurrencyName(_ string: String) {
        self.inputCurrencyTitle = string
    }
    
    func setOutputCurrencyName(_ string: String) {
        self.outputCurrencyTitle = string
    }
    
    func setInputValueText(_ string: String) {
        self.inputValueText = string
    }
    
}

//MARK: - UXUIFrameworkSwitching
extension ContentViewModel:UXUIFrameworkSwitching {
    func switchToUIKit() {
        withAnimation {
            self.isUIKit = true
            self.toggleUIActionName = kToSwiftUIActionName
        }
    }
    
    func switchToSwiftUI() {
        withAnimation {
            self.isUIKit = false
            self.toggleUIActionName = kToUIKitActionName
        }
    }
    
}
