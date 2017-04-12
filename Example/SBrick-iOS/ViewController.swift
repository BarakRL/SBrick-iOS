//
//  ViewController.swift
//  SBrick-iOS
//
//  Created by Barak Harel on 04/03/2017.
//  Copyright (c) 2017 Barak Harel. All rights reserved.
//

import UIKit
import SBrick
import CoreBluetooth

class ViewController: UIViewController, SBrickManagerDelegate, SBrickDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    var manager: SBrickManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = SBrickManager(delegate: self)
        
        statusLabel.text = "Discovering..."
        manager.startDiscovery()
    }
    
    func sbrickManager(_ sbrickManager: SBrickManager, didDiscover sbrick: SBrick) {
        
        //stop for now
        sbrickManager.stopDiscovery()
        
        statusLabel.text = "Found: \(sbrick.manufacturerData.deviceIdentifier)"
        
        //connect
        sbrick.delegate = self
        sbrickManager.connect(to: sbrick)
    }
    
    func sbrickManager(_ sbrickManager: SBrickManager, didUpdateBluetoothState bluetoothState: CBManagerState) {
        
    }
    
    func sbrickConnected(_ sbrick: SBrick) {
        statusLabel.text = "SBrick connected!"
    }
    
    func sbrickDisconnected(_ sbrick: SBrick) {
        statusLabel.text = "SBrick disconnected :("
    }
    
    func sbrickReady(_ sbrick: SBrick) {
        
        statusLabel.text = "SBrick ready!"
        
        sbrick.send(command: .write(bytes: [0x2C,0x01]))
        
        adcTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            
            guard let _self = self else { return }
            guard let sbrick = _self.manager.sbricks.first else { return }
            
//            sbrick.send(command: .queryADC(channelId: 0x00)) { (bytes) in
//                print("ADC 00: \(bytes.uint16littleEndianValue())")
//            }
            
            sbrick.send(command: .queryADC(channelId: 0x01)) { (bytes) in
                
//                let voltage = (bytes.voltageValue() - 1.4) / 1.4
//                print("ADC: \(voltage)")
                print("ADC 01: \(bytes.uint16littleEndianValue()/16)")
                
//                if voltage > 0.7 && !_self.isDriving {
//                    _self.isDriving = true
//                    sbrick.send(command: .drive(channelId: 0x02, cw: true, power: 255))
//                }
//                else if voltage < 0.7 && _self.isDriving {
//                    _self.isDriving = false
//                    sbrick.send(command: .stop(channelId: 0x02))
//                }
            }
        })
    }
    
    var isDriving = false
    
    var adcTimer: Timer?
    
    func sbrick(_ sbrick: SBrick, didRead data: Data?) {
        
        guard let data = data else { return }
        print("sbrick [\(sbrick.name)] did read: \([UInt8](data))")
        
        if sbrick.channelValues.count > 0 {
            let channelValue = sbrick.channelValues[0]
            print("sbrick channel 0 voltage: \(SBrick.voltage(from: channelValue))")
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        guard let sbrick = manager.sbricks.first else { return }
        sbrick.send(command: .stop(channelId: 0))
    }
    
    @IBAction func halfPowerCW(_ sender: Any) {
        guard let sbrick = manager.sbricks.first else { return }
        sbrick.send(command: .drive(channelId: 0, cw: true, power: 0x80)) { bytes in
            print("ok")
        }
    }
    
    @IBAction func fullPowerCW(_ sender: Any) {
        guard let sbrick = manager.sbricks.first else { return }
        sbrick.send(command: .drive(channelId: 0, cw: true, power: 0xFF)) { bytes in
            print("ok")
        }
    }
    
    @IBAction func halfPowerCCW(_ sender: Any) {
        guard let sbrick = manager.sbricks.first else { return }
        sbrick.send(command: .drive(channelId: 0, cw: false, power: 0x80)) { bytes in
            print("ok")
        }
    }
    
    @IBAction func fullPowerCCW(_ sender: Any) {
        guard let sbrick = manager.sbricks.first else { return }
        sbrick.send(command: .drive(channelId: 0, cw: false, power: 0xFF)) { bytes in
            print("ok")
        }
    }
}

