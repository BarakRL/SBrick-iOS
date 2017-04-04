//
//  SBrick.swift
//  SBrickTest
//
//  Created by Barak Harel on 4/3/17.
//  Copyright © 2017 Barak Harel. All rights reserved.
//

import Foundation
import CoreBluetooth

enum SBrickCommand {
    
    case drive(channelId: UInt8, cw: Bool, power: UInt8)
    case stop(channelId: UInt8)
    case getBrickID
    case getWatchDog
    
    func command() -> [UInt8] {
        
        switch self {
            
        case .drive(let channelId, let cw, let power):
            
            return [0x01, channelId, cw ? 0x01: 0x00, power]
            
        case .stop(let channelId):
            return [0x00, channelId]            
            
        case .getBrickID:
            return [0x0A]
            
        case .getWatchDog:
            return [0x0E]
            
        }
    }
}

protocol SBrickDelegate: class {
    func sbrick(_ sbrick: SBrick, didRead data: Data)
    func sbrickConnected(_ sbrick: SBrick)
    func sbrickDisconnected(_ sbrick: SBrick)
    func sbrickReady(_ sbrick: SBrick)
}

class SBrick: NSObject, CBPeripheralDelegate {
    
    static let RemoteControlServiceUUID = "4dc591b0-857c-41de-b5f1-15abda665b0c"
    
    static let RemoteControlCommandsCharacteristicUUID = "02B8CBCC-0E25-4BDA-8790-A15F53E6010F"
    private var remoteControlCommandsCharacteristic:CBCharacteristic?    
    //TO DO:
    //static let QuickDriveCharacteristicUUID = "489A6AE0-C1AB-4C9C-BDB2-11D373C1B7FB"
    //var quickDriveCharacteristic:CBCharacteristic?
    
    
    let peripheral:CBPeripheral
    let name: String
    let manufacturerData: ManufacturerData
    
    private var watchDog: Timer?
    
    weak var delegate: SBrickDelegate?
    
    init?(peripheral:CBPeripheral, advertisementData: [String : Any]) {
        
        guard let data = advertisementData["kCBAdvDataManufacturerData"] as? Data else { return nil }
        guard let manufacturerData = ManufacturerData(data: data) else { return nil }
        
        self.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "N/A"
        self.peripheral = peripheral
        self.manufacturerData = manufacturerData
        
        super.init()
    }
    
    static func ==(lhs: SBrick, rhs: SBrick) -> Bool {
        return lhs.peripheral.isEqual(rhs.peripheral)
    }
    
    func didConnect() {
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: SBrick.RemoteControlServiceUUID)])
        
        delegate?.sbrickConnected(self)
    }
    
    func didDisconnect() {
        //Cleanup
        watchDog?.invalidate()
        watchDog = nil
        
        delegate?.sbrickDisconnected(self)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let error = error {
            print("ERROR DISCOVERING SERVICES: \(error.localizedDescription)")
            return
        }
        
        if let services = peripheral.services {
            
            for service in services {
                if service.uuid == CBUUID(string: SBrick.RemoteControlServiceUUID) {
                    peripheral.discoverCharacteristics([CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID)], for: service)
                }
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID) {
                    remoteControlCommandsCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    delegate?.sbrickReady(self)
                }
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error.localizedDescription)")
            return
        }
        
        guard characteristic.uuid == CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID) else { return }
        
        if let dataBytes = characteristic.value {
            delegate?.sbrick(self, didRead: dataBytes)
        }
    }
    
    func send(command: SBrickCommand) {
        self.send(command.command())
    }
    
    func send(_ command:[UInt8]) {
        
        guard let characteristic = self.remoteControlCommandsCharacteristic else { return }
        
        if watchDog == nil {
            watchDog = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] (timer) in
                self?.send(command: .getWatchDog)
            })
        }
        
        var rawArray = command
        let data = NSData(bytes: &rawArray, length: rawArray.count)
        peripheral.writeValue(data as Data, for: characteristic, type: .withResponse)
    }
    
    func read() {
        
        guard let characteristic = self.remoteControlCommandsCharacteristic else { return }
        
        peripheral.readValue(for: characteristic)
    }
    
}
