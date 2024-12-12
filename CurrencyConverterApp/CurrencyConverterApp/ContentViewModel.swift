//
//  ContentViewModel.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 12.12.2024.
//

import Foundation
import Combine

class ContentViewModel:ObservableObject {
    
    @Published var inProgress:Bool = false
    
    let interactor: any CurrencyConversionInteraction
    private lazy var _isCountdown:CurrentValueSubject<Bool, Never> = .init(false)
    
    private var lifetimeSubscriptions:Set<AnyCancellable> = []
    
    init(with conversionInteractor: any CurrencyConversionInteraction) {
        self.interactor = conversionInteractor
        
        conversionInteractor.isPendingRequest
            .receive(on: DispatchQueue.main)
            .assign(to: \.inProgress, on: self)
            .store(in: &lifetimeSubscriptions)
    }
}


//MARK: - CountdownActivePublisherContainer
extension ContentViewModel: CountdownActivePublisherContainer {
    var isCountdownActive:AnyPublisher<Bool, Never> {
        self._isCountdown.eraseToAnyPublisher()
    }
}
