//
//  ViewController.swift
//  MarsV1
//
//  Created by 이정원 on 26/05/2019.
//  Copyright © 2019 Jungwon Lee. All rights reserved.
//

import UIKit

enum Feature: Int {
    case solarPanels = 0, greenhouses, size }

class ViewController: UIViewController,UIPickerViewDelegate {
    /* Initialize CoreML Model */
    let model = MarsHabitatPricer()
    
    /// Data source for the picker.
    let pickerDataSource = PickerDataSource()
    
    /// Formatter for the output.
    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
   
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var pickerView: UIPickerView!{
        didSet {
            
            pickerView.delegate = self
            
            pickerView.dataSource = pickerDataSource
            
            let features: [Feature] = [.solarPanels, .greenhouses, .size]
            
            /* Initial Row Selected */
            for feature in features {
                pickerView.selectRow(2, inComponent: feature.rawValue, animated: false)
                print("Componet: feature.rawValue=",feature.rawValue)
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updatePredictedPrice()
    }
    
    /// Accessor for picker values.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let feature = Feature(rawValue: component) else {
            fatalError("Invalid component \(component) found to represent a \(Feature.self). This should not happen based on the configuration set in the storyboard.")
        }
        
        return pickerDataSource.title(for: row, feature: feature)
    }
    
    /// When values are changed, update the predicted price.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(" Selected row=",row, component)
        
        //updatePredictedPrice()
        updatePredictedPrice()
    }
    
    func updatePredictedPrice() {
        func selectedRow(for feature: Feature) -> Int {
            return pickerView.selectedRow(inComponent: feature.rawValue)
        }
        
        let solarPanels = pickerDataSource.value(for: selectedRow(for: .solarPanels), feature: .solarPanels)
        let greenhouses = pickerDataSource.value(for: selectedRow(for: .greenhouses), feature: .greenhouses)
        let size = pickerDataSource.value(for: selectedRow(for: .size), feature: .size)
        
        print("solarPanels =", solarPanels, greenhouses, size)
        
        guard let marsHabitatPricerOutput = try? model.prediction(solarPanels: solarPanels, greenhouses: greenhouses, size: size) else {
            fatalError("Unexpected runtime error.")
        }
        
        let price = marsHabitatPricerOutput.price
        priceLabel.text = priceFormatter.string(for: price)
    }
}


class PickerDataSource: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - Properties
    
    private let solarPanelsDataSource = SolarPanelDataSource()
    private let greenhousesDataSource = GreenhousesDataSource()
    private let sizeDataSource = SizeDataSource()
    
    // MARK: - Helpers
    
    /// Find the title for the given feature.
    func title(for row: Int, feature: Feature) -> String? {
        switch feature {
        case .solarPanels:  return solarPanelsDataSource.title(for: row)
        case .greenhouses:  return greenhousesDataSource.title(for: row)
        case .size:         return sizeDataSource.title(for: row)
        }
    }
    
    /// For the given feature, find the value for the given row.
    func value(for row: Int, feature: Feature) -> Double {
        let value: Double?
        
        switch feature {
        case .solarPanels:      value = solarPanelsDataSource.value(for: row)
        case .greenhouses:      value = greenhousesDataSource.value(for: row)
        case .size:             value = sizeDataSource.value(for: row)
        }
        
        return value!
    }
    
    // MARK: - UIPickerViewDataSource
    
    /// Hardcoded 3 items in the picker.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    /// Find the count of each column of the picker.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Feature(rawValue: component)! {
        case .solarPanels:  return solarPanelsDataSource.values.count
        case .greenhouses:  return greenhousesDataSource.values.count
        case .size:         return sizeDataSource.values.count
        }
    }
    
}

struct SolarPanelDataSource {
    /// Possible values for solar panels in the habitat
    let values = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5]
    
    func title(for index: Int) -> String? {
        guard index < values.count else { return nil }
        return String(values[index])
    }
    
    func value(for index: Int) -> Double? {
        guard index < values.count else { return nil }
        return Double(values[index])
    }
}
struct GreenhousesDataSource {
    /// Possible values for greenhouses in the habitat
    let values = [1, 2, 3, 4, 5]
    
    func title(for index: Int) -> String? {
        guard index < values.count else { return nil }
        return String(values[index])
    }
    
    func value(for index: Int) -> Double? {
        guard index < values.count else { return nil }
        return Double(values[index])
    }
}

struct SizeDataSource {
    /// Helper formatter to represent large nubmers in the picker
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    /// Possible values for size of the habitat.
    let values = [
        750,
        1000,
        1500,
        2000,
        3000,
        4000,
        5000,
        10_000
    ]
    
    func title(for index: Int) -> String? {
        guard index < values.count else { return nil }
        return SizeDataSource.numberFormatter.string(from: NSNumber(value: values[index]))
    }
    
    func value(for index: Int) -> Double? {
        guard index < values.count else { return nil }
        return Double(values[index])
    }
}
