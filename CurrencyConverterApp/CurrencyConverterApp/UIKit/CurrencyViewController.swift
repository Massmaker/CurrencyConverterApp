//
//  CurrencyViewController.swift
//  CurrencyConverterApp
//
//  Created by Ivan Yavorin on 13.12.2024.
//

import UIKit
import Combine

protocol ContentViewModelType {
    var currencyTitles:[String] { get }
    var toggleConversionIconNamePublisher:AnyPublisher<String, Never> { get }
    var backwardConversionPublisher:AnyPublisher<Bool, Never> { get }
    var outputValueTextPublisher:AnyPublisher<String, Never> { get }
    var isAlertPublisher:AnyPublisher<Bool, Never> {get}
    var alertInfoData:AlertInfo? {get}
    var inputText:String?{get}
    func uiActionToggleConversionDirection()
    func setInputCurrencyName(_ string:String)
    func setOutputCurrencyName(_ string:String)
    func setInputValueText(_ string:String)
}

protocol UXUIFrameworkSwitching {
    func switchToUIKit()
    func switchToSwiftUI()
}

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
        //horStack.spacing = 16
        
        return horStack
    }()

    private lazy var textsHorizontalStack:UIStackView = {
        let horStack = UIStackView()
        horStack.axis = .horizontal
        horStack.distribution = .fillEqually
        horStack.spacing = 16
        horStack.alignment = .top
        return horStack
    }()
    
    private var lifetimeSubscriptions:Set<AnyCancellable> = []
    
    let viewModel: any ContentViewModelType
    let uiuxSwitcher: any UXUIFrameworkSwitching
    
    init(viewModel:any ContentViewModelType, uxUiSwitcher: any UXUIFrameworkSwitching) {
        
        self.viewModel = viewModel
        self.uiuxSwitcher = uxUiSwitcher
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
        
        let leftpicker = UIPickerView()
        self.fromCurrencyPicker = leftpicker
        leftpicker.delegate = self.fromPickerDelegate
        leftpicker.dataSource = self.fromPickerDataSource
        leftpicker.translatesAutoresizingMaskIntoConstraints = false
        leftpicker.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
        
        let rightPicker = UIPickerView()
        
        self.toCurrencyPicker = rightPicker
        rightPicker.delegate = self.toPickerDelegate
        rightPicker.dataSource = self.toPickerDataSource
        rightPicker.translatesAutoresizingMaskIntoConstraints = false
        rightPicker.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
        
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.image = UIImage(systemName: kArrowLeftName)
        
        let directionButton = UIButton(configuration: buttonConfig)
        self.directionToggleButton = directionButton
        directionButton.addAction( UIAction{[unowned self] _ in
            self.uiToggleConversionDirectionAction()
        }, for: UIControl.Event.touchUpInside)
         
        directionButton.translatesAutoresizingMaskIntoConstraints = false
        directionButton.heightAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true
        directionButton.widthAnchor.constraint(lessThanOrEqualToConstant: 60).isActive = true

        
        self.pickersHorizontalStack.addArrangedSubview(leftpicker)
        self.pickersHorizontalStack.addArrangedSubview(directionButton)
        self.pickersHorizontalStack.addArrangedSubview(rightPicker)
        
        
        let tf = UITextField()
        self.fromValueTextField = tf
        tf.delegate = self.textFieldDelegate
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numbersAndPunctuation
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.text = self.viewModel.inputText
        self.textsHorizontalStack.addArrangedSubview(tf)
        
        let labelContainer:UIView = UIView()
        labelContainer.layer.cornerRadius = 12
        labelContainer.layer.borderWidth = 2
        labelContainer.layer.borderColor = UIColor.accent.cgColor
        self.resultLabelContainer = labelContainer
        
        let resLabel = UILabel()
        self.resultLabel = resLabel
        resLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        resLabel.translatesAutoresizingMaskIntoConstraints = false
        
        labelContainer.addSubview(resLabel)
        
//        resLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let labelInsideContainerConstraints:[NSLayoutConstraint] = [
            
            NSLayoutConstraint(item: resLabel, attribute: .top, relatedBy: .equal, toItem: labelContainer, attribute: .top, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: resLabel, attribute: .bottom, relatedBy: .equal, toItem: labelContainer, attribute: .bottom, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: resLabel, attribute: .leading, relatedBy: .equal, toItem: labelContainer, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: resLabel, attribute: .trailing, relatedBy: .equal, toItem: labelContainer, attribute: .trailing, multiplier: 1, constant: -8),
//            NSLayoutConstraint(item: resLabel, attribute: .centerX, relatedBy: .equal, toItem: labelContainer, attribute: .centerX, multiplier: 1, constant:0),
//            NSLayoutConstraint(item: resLabel, attribute: .centerY, relatedBy: .equal, toItem: labelContainer, attribute: .centerY, multiplier: 1, constant:0)
            NSLayoutConstraint(item: labelContainer, attribute: .height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
        ]
        
        NSLayoutConstraint.activate(labelInsideContainerConstraints)
        
        self.textsHorizontalStack.addArrangedSubview(labelContainer)
        
        let backToSwiftUIButton = UIButton(type: .system)
        
        backToSwiftUIButton.setTitle(kToSwiftUIActionName, for: UIControl.State.normal)
        
        backToSwiftUIButton.addAction(UIAction { _ in
            self.uiuxSwitcher.switchToSwiftUI()
        }, for: UIControl.Event.touchUpInside)
        
        let horizontalBottomStack = UIStackView(arrangedSubviews: [backToSwiftUIButton])
        horizontalBottomStack.axis = .horizontal
        horizontalBottomStack.alignment = .leading
        self.verticalStack.addArrangedSubview(horizontalBottomStack)
    }
    
    private func subscribeToViewModelChanges() {
        subsribeToConversionDirectionUIChange()
        subscribeToResultTextChange()
        subscribeToPossibleAlerts()
    }
    
    
    private func subsribeToConversionDirectionUIChange() {
        viewModel.toggleConversionIconNamePublisher
            .sink {[unowned self] iconName in
                guard let image = UIImage(systemName: iconName) else {
                    return
                }
                
                self.directionToggleButton.setImage(image, for: UIControl.State.normal)
            }
            .store(in: &lifetimeSubscriptions)
        
        // to change text field's and result label's horizontal positioning
        viewModel.backwardConversionPublisher
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
        self.viewModel.outputValueTextPublisher
            .sink { [unowned self] resultText in
                self.resultLabel.text = resultText
            }
            .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeToPossibleAlerts() {
        self.viewModel.isAlertPublisher
            .sink {[unowned self] isDisplayingAlert in
                guard let alertInfo = self.viewModel.alertInfoData else {
                    return
                }
                
                self.presentAlert(alertInfo)
            }
            .store(in: &lifetimeSubscriptions)
    }
    
    //MARK: -
    @objc private func uiToggleConversionDirectionAction() {
        self.viewModel.uiActionToggleConversionDirection()
    }
    
    private func presentAlert(_ alertInfo:AlertInfo) {
        let alertController = UIAlertController.createWith(alertInfo)
        self.present(alertController, animated: true, completion: {
            // finished alert presentation
        })
    }

}

//MARK: - UIKitPickerSelectionReceiver
extension CurrencyViewController: UIKitPickerSelectionReceiver {
    func receiveSelectedCurrencyName(_ name: String, fromPicker picker: UIPickerView) {
        if picker == self.fromCurrencyPicker {
            viewModel.setInputCurrencyName(name)
        }
        else if picker == self.toCurrencyPicker {
            viewModel.setOutputCurrencyName(name)
        }
    }
}

//MARK: - CurrencyFromValueChangeReceiving
extension CurrencyViewController: CurrencyFromValueChangeReceiving {
    func receiveCurrencyValueText(_ string: String) {
        self.viewModel.setInputValueText(string)
    }
}

 
