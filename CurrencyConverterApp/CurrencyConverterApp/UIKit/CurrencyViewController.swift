//
//  CurrencyViewController.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import UIKit
import Combine

class CurrencyViewController: UIViewController {

    private var fromCurrencyPicker: UIPickerView!
    private var toCurrencyPicker: UIPickerView!
    private var directionToggleButton: UIButton!
    private var fromValueTextField: UITextField!
    private var resultLabel: UILabel!
    private var resultLabelContainer:UIView!
    
    private var fromPickerDelegate: UIPickerDelegate?
    private var toPickerDelegate: UIPickerDelegate?
    
    private var fromPickerDataSource: UIPickerDataSource?
    private var toPickerDataSource: UIPickerDataSource?
    private var textFieldDelegate: UITextFieldDelegate?
    
    private lazy var verticalStack:UIStackView = {
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 24
        vStack.translatesAutoresizingMaskIntoConstraints = false
        return vStack
    }()
    
    private lazy var pickersHorizontalStack:UIStackView = {
        let horStack = UIStackView()
        horStack.axis = .horizontal
        horStack.spacing = 16
        
        return horStack
    }()

    private lazy var textsHorizontalStack:UIStackView = {
        let horStack = UIStackView()
        horStack.axis = .horizontal
        horStack.distribution = .equalCentering
        horStack.spacing = 16
        horStack.alignment = .top
        return horStack
    }()
    
    private var lifetimeSubscriptions:Set<AnyCancellable> = []
    
    let viewModel:ContentViewModel
    
    init(viewModel:ContentViewModel) {
        
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createInternalDelegates()
        createSubviews()
        subscribeToViewModelChanges()
    }
    
    private func createInternalDelegates() {
        let currencyTitles =  viewModel.currencyTitles
        let fromPickerDelegate = UIPickerDelegate(currencyTitles: currencyTitles, selectionReceiver: WeakObject(self))
        let toPickerDelegate = UIPickerDelegate(currencyTitles: currencyTitles, selectionReceiver: WeakObject(self))
        self.fromPickerDelegate = fromPickerDelegate
        self.toPickerDelegate = toPickerDelegate
        
        let fromDS = UIPickerDataSource(currencyTitles: currencyTitles)
        let toDS = UIPickerDataSource(currencyTitles: currencyTitles)
        self.fromPickerDataSource = fromDS
        self.toPickerDataSource = toDS
        
        self.textFieldDelegate = UITextFieldDelegateCallsHandler(textChangeReceiver: WeakObject(self)) //it is UITextFieldDelegte conforming class
    }
    
    private func createSubviews() {

        let vStack = self.verticalStack
        let rootView = self.view
        
        rootView?.addSubview(vStack)
        
        let vStackConstrants:[NSLayoutConstraint] = [
            NSLayoutConstraint(item: vStack, attribute: .top, relatedBy: .equal, toItem: rootView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: vStack, attribute: .bottom, relatedBy: .equal, toItem: rootView, attribute: .bottom, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: vStack, attribute: .leading, relatedBy: .equal, toItem: rootView, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: vStack, attribute: .trailing, relatedBy: .equal, toItem: rootView, attribute: .trailing, multiplier: 1, constant: 0),
        ]
        
        NSLayoutConstraint.activate(vStackConstrants)
        
        self.verticalStack.addArrangedSubview(self.pickersHorizontalStack)
        self.verticalStack.addArrangedSubview(self.textsHorizontalStack)
//        self.view.addSubview(self.pickersHorizontalStack)
//        let horStackConstraints:[NSLayoutConstraint] = [
//            NSLayoutConstraint(item: self.horizontalStack,
//                               attribute: .top,
//                               relatedBy: NSLayoutConstraint.Relation.equal,
//                               toItem: self.view,
//                               attribute: .top,
//                               multiplier: 1.0,
//                               constant: 0),
//            
//            NSLayoutConstraint(item: self.horizontalStack,
//                               attribute: .leadingMargin,
//                               relatedBy: NSLayoutConstraint.Relation.equal,
//                               toItem: self.view,
//                               attribute: .leadingMargin,
//                               multiplier: 1.0,
//                               constant: 0),
//            
//            NSLayoutConstraint(item: self.horizontalStack,
//                               attribute: .trailingMargin,
//                               relatedBy: NSLayoutConstraint.Relation.equal,
//                               toItem: self.view,
//                               attribute: .trailingMargin,
//                               multiplier: 1.0,
//                               constant: 0)
//        ]
//            
//        NSLayoutConstraint.activate(horStackConstraints)
        
        
        let leftpicker = UIPickerView()
        self.fromCurrencyPicker = leftpicker
        leftpicker.delegate = self.fromPickerDelegate
        leftpicker.dataSource = self.fromPickerDataSource
        
        let rightPicker = UIPickerView()
        
        self.toCurrencyPicker = rightPicker
        rightPicker.delegate = self.toPickerDelegate
        rightPicker.dataSource = self.toPickerDataSource
        
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.image = UIImage(systemName: kArrowLeftName)
        
        let directionButton = UIButton(configuration: buttonConfig)
        self.directionToggleButton = directionButton
        directionButton.addAction( UIAction{[unowned self] _ in
            self.uiToggleConversionDirectionAction()
        }, for: UIControl.Event.touchUpInside)
                                  
                                  
//        directionButton.addTarget(self, action: #selector(uiToggleConversionDirectionAction), for: UIControl.Event.touchUpInside)
        
        self.pickersHorizontalStack.addArrangedSubview(leftpicker)
        self.pickersHorizontalStack.addArrangedSubview(directionButton)
        self.pickersHorizontalStack.addArrangedSubview(rightPicker)
        
        
        let tf = UITextField()
        self.fromValueTextField = tf
        tf.delegate = self.textFieldDelegate
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        self.textsHorizontalStack.addArrangedSubview(tf)
        
        let labelContainer:UIView = UIView()
        labelContainer.layer.cornerRadius = 12
        labelContainer.layer.borderWidth = 2
        labelContainer.layer.borderColor = UIColor.accent.cgColor
        
        let resLabel = UILabel()
        self.resultLabel = resLabel
        resLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        resLabel.translatesAutoresizingMaskIntoConstraints = false
        
        labelContainer.addSubview(resLabel)
        
        resLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let labelInsideContainerConstraints:[NSLayoutConstraint] = [
            
            NSLayoutConstraint(item: resLabel, attribute: .top, relatedBy: .equal, toItem: labelContainer, attribute: .top, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: resLabel, attribute: .bottom, relatedBy: .equal, toItem: labelContainer, attribute: .bottom, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: resLabel, attribute: .leading, relatedBy: .equal, toItem: labelContainer, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: resLabel, attribute: .trailing, relatedBy: .equal, toItem: labelContainer, attribute: .trailing, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: resLabel, attribute: .centerX, relatedBy: .equal, toItem: labelContainer, attribute: .centerX, multiplier: 1, constant:0),
            NSLayoutConstraint(item: resLabel, attribute: .centerY, relatedBy: .equal, toItem: labelContainer, attribute: .centerY, multiplier: 1, constant:0)
        ]
        
        NSLayoutConstraint.activate(labelInsideContainerConstraints)
        
        self.textsHorizontalStack.addArrangedSubview(labelContainer)
    }
    
    private func subscribeToViewModelChanges() {
        subsribeToConversionDirectionUIChange()
        subscribeToResultTextChange()
    }
    
    
    private func subsribeToConversionDirectionUIChange() {
        viewModel.$toggleConversionIconName
            .sink {[unowned self] iconName in
                guard let image = UIImage(systemName: iconName) else {
                    return
                }
                
                self.directionToggleButton.setImage(image, for: UIControl.State.normal)
            }
            .store(in: &lifetimeSubscriptions)
        
        // to change text field's and result label's horizontal positioning
        viewModel.$backwardConversion
            .sink { [unowned self] isBackwards in
                let subviews = self.textsHorizontalStack.arrangedSubviews
                guard subviews.count > 2 else {
                    return
                }
                
                guard let firstSubview = subviews.first,
                      let lastSubview = subviews.last, firstSubview != lastSubview else {
                    return
                }
                
                if isBackwards, firstSubview == self.fromValueTextField, lastSubview == self.resultLabelContainer {
                    //put the input textField at trailing and resutLabel at leading
                    
                    subviews.forEach {
                        self.textsHorizontalStack.removeArrangedSubview($0)
                    }
                    
                    self.textsHorizontalStack.addArrangedSubview(lastSubview)
                    self.textsHorizontalStack.addArrangedSubview(firstSubview)
                }
                else if !isBackwards, firstSubview == self.resultLabelContainer, lastSubview == self.fromValueTextField {
                    
                    //put the input textField at leading and resutLabel at trailing
                    subviews.forEach {
                        self.textsHorizontalStack.removeArrangedSubview($0)
                    }
                    
                    self.textsHorizontalStack.addArrangedSubview(lastSubview)
                    self.textsHorizontalStack.addArrangedSubview(firstSubview)
                }
            }
            .store(in: &lifetimeSubscriptions)
    }

    private func subscribeToResultTextChange() {
        self.viewModel.$outputValueText
            .sink { [unowned self] resultText in
                self.resultLabel.text = resultText
        }
            .store(in: &lifetimeSubscriptions)
    }
    
    @objc private func uiToggleConversionDirectionAction() {
        self.viewModel.uiActionToggleConversionDirection()
    }

}

//MARK: - UIKitPickerSelectionReceiver
extension CurrencyViewController: UIKitPickerSelectionReceiver {
    func receiveSelectedCurrencyName(_ name: String, fromPicker picker: UIPickerView) {
        if picker == self.fromCurrencyPicker {
            viewModel.inputCurrencyTitle = name
        }
        else if picker == self.toCurrencyPicker {
            viewModel.outputCurrencyTitle = name
        }
    }
}

//MARK: - CurrencyFromValueChangeReceiving
extension CurrencyViewController: CurrencyFromValueChangeReceiving {
    func receiveCurrencyValueText(_ string: String) {
        self.viewModel.inputValueText = string
    }
}
