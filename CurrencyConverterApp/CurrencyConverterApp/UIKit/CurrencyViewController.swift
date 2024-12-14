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
    var toggleConversionIconNamePublisher:AnyPublisher<String, Never> { get } //arrow left or arrow right
    var isOppositeDirectionConversionPublisher:AnyPublisher<Bool, Never> { get } //from leading to trailing currency or vice versa
    var outputValueTextPublisher:AnyPublisher<String, Never> { get } //conversion result string
    var isFetchingConversionDataPublisher:AnyPublisher<Bool, Never> {get} //to disable the ui if needed or somehow indicate the process
    var isAlertPublisher:AnyPublisher<Bool, Never> {get}
    var alertInfoData:AlertInfo? {get}
    var inputText:String?{get} //initial input text if any
    var inputCurrencyName:String? {get} //initial selected input currency
    var outputCurrencyName:String? {get} //initial selected output currency
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
    
    private var activityIndicator:UIActivityIndicatorView?
    
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
        horStack.distribution = .equalSpacing
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
        
        //Left Picker
        let leftpicker = UIPickerView()
        self.fromCurrencyPicker = leftpicker
        leftpicker.dataSource = self.fromPickerDataSource
        
        //pre-set the selected item in left picker
        if let preSelectedCurrencyName = self.viewModel.inputCurrencyName,
           let indexOfRow = self.viewModel.currencyTitles.firstIndex(where: {$0 == preSelectedCurrencyName}) {
            leftpicker.selectRow(indexOfRow, inComponent: 0, animated: false)
        }
        
        //then assign a delegate
        leftpicker.delegate = self.fromPickerDelegate
        
        leftpicker.translatesAutoresizingMaskIntoConstraints = false
        
        //Left Picker Constraints
        leftpicker.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
        
        //minimal height
        leftpicker.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        
        //default height
        let heightLowerPriorityConstraintLeft:NSLayoutConstraint = leftpicker.heightAnchor.constraint(equalToConstant: 150)
        heightLowerPriorityConstraintLeft.priority = .defaultLow
        heightLowerPriorityConstraintLeft.isActive = true
        
        //Right Picker
        let rightPicker = UIPickerView()
        self.toCurrencyPicker = rightPicker
        rightPicker.dataSource = self.toPickerDataSource
        
        //pre-set the selected item in right picker
        if let preSelectedOutCurrencyName = self.viewModel.outputCurrencyName,
           let indexOfRow = self.viewModel.currencyTitles.firstIndex(where: {$0 == preSelectedOutCurrencyName}) {
            rightPicker.selectRow(indexOfRow, inComponent: 0, animated: false)
        }
        
        //then assign a delegate
        rightPicker.delegate = self.toPickerDelegate
        
        rightPicker.translatesAutoresizingMaskIntoConstraints = false
        
        //Right Picker Constraints
        rightPicker.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
        //minimal height
        rightPicker.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        //default height
        let heightLowerPriorityConstraintRight:NSLayoutConstraint = rightPicker.heightAnchor.constraint(equalToConstant: 150)
        heightLowerPriorityConstraintRight.priority = .defaultLow
        heightLowerPriorityConstraintRight.isActive = true
        
        //Direction Change button
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

        let buttonContainerStack = UIStackView(arrangedSubviews: [directionButton])
        buttonContainerStack.axis = .vertical
        buttonContainerStack.alignment = .center
        buttonContainerStack.distribution = .equalCentering
        
        self.pickersHorizontalStack.addArrangedSubview(leftpicker)
        self.pickersHorizontalStack.addArrangedSubview(buttonContainerStack)
        self.pickersHorizontalStack.addArrangedSubview(rightPicker)
        
        //Input Value Text Field
        let tf = UITextField()
        self.fromValueTextField = tf
        tf.delegate = self.textFieldDelegate
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numbersAndPunctuation
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.text = self.viewModel.inputText
        self.textsHorizontalStack.addArrangedSubview(tf)
        
        //Result Label
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
        
        // UI Framework toggle button
        let backToSwiftUIButton = UIButton(type: .system)
        
        backToSwiftUIButton.setTitle(kToSwiftUIActionName, for: UIControl.State.normal)
        
        backToSwiftUIButton.addAction(UIAction { _ in
            self.uiuxSwitcher.switchToSwiftUI()
        }, for: UIControl.Event.touchUpInside)
        
        let horizontalBottomStack = UIStackView(arrangedSubviews: [backToSwiftUIButton])
        horizontalBottomStack.axis = .horizontal
        horizontalBottomStack.alignment = .leading
        self.verticalStack.addArrangedSubview(horizontalBottomStack)
        
        
        //Simple Activity Indicator
        let activity = UIActivityIndicatorView(style: .large)
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator = activity
        
        self.view.addSubview(activity)
        
        activity.centerXAnchor.constraint(equalTo: self.verticalStack.centerXAnchor, constant: 0).isActive = true
        activity.centerYAnchor.constraint(equalTo: self.verticalStack.centerYAnchor, constant: 0).isActive = true
    }
    
    private func subscribeToViewModelChanges() {
        subsribeToConversionDirectionUIChange()
        subscribeToResultTextChange()
        subscribeToPossibleAlerts()
        subscribeToFetchingInProgressChange()
    }
    
    
    private func subsribeToConversionDirectionUIChange() {
        viewModel.toggleConversionIconNamePublisher
            .receive(on: DispatchQueue.main)
            .sink {[unowned self] iconName in
                guard let image = UIImage(systemName: iconName) else {
                    return
                }
                
                self.directionToggleButton.setImage(image, for: UIControl.State.normal)
            }
            .store(in: &lifetimeSubscriptions)
        
        // to change text field's and result label's horizontal positioning
        viewModel.isOppositeDirectionConversionPublisher
            .receive(on: DispatchQueue.main)
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
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] resultText in
                self.resultLabel.text = resultText
            }
            .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeToPossibleAlerts() {
        self.viewModel.isAlertPublisher
            .receive(on: DispatchQueue.main)
            .sink {[unowned self] isDisplayingAlert in
                guard let alertInfo = self.viewModel.alertInfoData else {
                    return
                }
                
                self.presentAlert(alertInfo)
            }
            .store(in: &lifetimeSubscriptions)
    }
    
    private func subscribeToFetchingInProgressChange() {
        
        self.viewModel.isFetchingConversionDataPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {[unowned self] isFetchingInProgress in
                if isFetchingInProgress {
                    self.activityIndicator?.startAnimating()
                }
                else {
                    self.activityIndicator?.stopAnimating()
                }
            })
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

 
