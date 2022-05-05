//
//  ViewController.swift
//  BLUE
//  Created by Erdal on 28.04.2022.

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    var RxData: String?
    var TxData: String?
    var BlueChart:CBCharacteristic?
    var centralManager:CBCentralManager!
    var scale:CBPeripheral?
    var peripheralManager: CBPeripheralManager?
    var periperalTXCharacteristic: CBCharacteristic?
    var characteristic = CBMutableCharacteristic(type: CBUUID(string: "0xFFE1"),
                                                         properties: [.notify],
                                                         value: nil,
                                                         permissions: .readable)
    
    let serviceUUID = CBUUID(string: "0xFFE0")
    let ChartUUID = CBUUID (string: "0xFFE1")
    
    @IBOutlet weak var sentButton: UIButton!
    @IBOutlet weak var TxTextField: UITextField!
    @IBOutlet weak var infoText: UITextView!
    @IBOutlet weak var clearInfoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager()
        centralManager.delegate = self
        //Close the keyborad
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    //MARK: - Control Manager Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
            infoText.text.append(contentsOf: "\n:scanning...")
            print("scanning...")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("found device")
        centralManager.stopScan()
        scale = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("connected : \(peripheral.name ?? "")")
        infoText.text.append(contentsOf: "\n:found device")
        infoText.text.append(contentsOf: "\n:Connected : \(peripheral.name!)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //if peripheral == self.scale {}
        peripheral.discoverServices([serviceUUID])
    }
    
    //MARK: - Peripheral Delegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: {$0.uuid == serviceUUID }) {
            peripheral.discoverCharacteristics([ChartUUID], for: service)
            print("service found")
            infoText.text.append(contentsOf: "\n:service found")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristic = service.characteristics?.first(where: {$0.uuid == ChartUUID }){
             peripheral.setNotifyValue(true, for: characteristic)
            BlueChart = characteristic
            print("characteristic found")
            infoText.text.append(contentsOf: "\n:characteristic found")
        }
       // if let characteristics = service.characteristics {
       //     for characteristic in characteristics {
       //         if characteristic.uuid == ChartUUID {
       //             print("chart found")
       //             BlueChart = characteristic
       //         }
       //     }
       //  }
    }
    //MARK: - Sent & Receive Data
    
    // Receive Data Functions
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            RxData = String(data: data, encoding: .utf8)
            print(RxData ?? "")
            infoText.text.append(contentsOf: "\n[Recv]: \(RxData!)")
        }
    }
    
    // Write Data Functions
     func writeCharacteristic(TxData: String){
       let TxDataString = (TxData as NSString).data(using: String.Encoding.utf8.rawValue)
          //change the "data" to valueString
            scale?.writeValue(TxDataString!, for: BlueChart!, type: .withoutResponse)
            print("sent : \(TxDataString!) : " + (TxTextField.text ?? ""))
            infoText.text.append(contentsOf: "\n[Send]: \(TxTextField.text!)")
     }
     
    @IBAction func sentButtonClick(_ sender: Any) {
        TxData = TxTextField.text
        writeCharacteristic(TxData: TxData ?? "")
        TxTextField.text = ""
    }
    
    @IBAction func clearButtonClick(_ sender: Any) {
        infoText.text = "info"
    }
    
    
    
}

