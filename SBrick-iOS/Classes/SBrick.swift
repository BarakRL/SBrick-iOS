//
//  SBrick.swift
//  SBrickTest
//
//  Created by Barak Harel on 4/3/17.
//  Copyright © 2017 Barak Harel. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol SBrickDelegate: class {
    func sbrick(_ sbrick: SBrick, didRead data: Data?)
    func sbrickConnected(_ sbrick: SBrick)
    func sbrickDisconnected(_ sbrick: SBrick)
    func sbrickReady(_ sbrick: SBrick)
}

public class SBrick: NSObject {
    
    public fileprivate(set) var channelValues:[UInt16]
    
    public enum Command {
        
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
    
    
    static let RemoteControlServiceUUID = "4dc591b0-857c-41de-b5f1-15abda665b0c"
    
    static let RemoteControlCommandsCharacteristicUUID = "02B8CBCC-0E25-4BDA-8790-A15F53E6010F"
    fileprivate var remoteControlCommandsCharacteristic:CBCharacteristic?
    
    static let QuickDriveCharacteristicUUID = "489A6AE0-C1AB-4C9C-BDB2-11D373C1B7FB"
    var quickDriveCharacteristic:CBCharacteristic?
    
    
    internal let peripheral:CBPeripheral
    public let name: String
    public let manufacturerData: ManufacturerData
    
    private var watchDog: Timer?
    
    public weak var delegate: SBrickDelegate?
    
    init?(peripheral:CBPeripheral, advertisementData: [String : Any]) {
        
        guard let data = advertisementData["kCBAdvDataManufacturerData"] as? Data else { return nil }
        guard let manufacturerData = ManufacturerData(data: data) else { return nil }
        
        self.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "N/A"
        self.peripheral = peripheral
        self.manufacturerData = manufacturerData
        
        self.channelValues = []
        
        super.init()
    }
    
    static func ==(lhs: SBrick, rhs: SBrick) -> Bool {
        return lhs.peripheral.isEqual(rhs.peripheral)
    }
    
    internal func didConnect() {
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: SBrick.RemoteControlServiceUUID)])
        
        DispatchQueue.main.async {
            self.delegate?.sbrickConnected(self)
        }
    }
    
    internal func didDisconnect() {
        //Cleanup
        watchDog?.invalidate()
        watchDog = nil
        
        DispatchQueue.main.async {
            self.delegate?.sbrickDisconnected(self)
        }
    }
    
    
    public func send(command: SBrick.Command) {
        self.send(command.command())
    }
    
    public func send(_ command:[UInt8]) {
        
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
    
    public func read() {
        
        guard let characteristic = self.remoteControlCommandsCharacteristic else { return }
        
        peripheral.readValue(for: characteristic)
    }
}

extension SBrick {
    
    public static func voltage(from value: UInt16) -> Double {
        return Double(value) * 0.83875 / 2047.0
    }
    
    public static func celsiusTemperature(from value: UInt16) -> Double {
        return Double(value) / 118.85795 - 160
    }
}

extension SBrick: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let error = error {
            print("ERROR DISCOVERING SERVICES: \(error.localizedDescription)")
            return
        }
        
        if let services = peripheral.services {
            
            for service in services {
                if service.uuid == CBUUID(string: SBrick.RemoteControlServiceUUID) {
                    peripheral.discoverCharacteristics([CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID), CBUUID(string: SBrick.QuickDriveCharacteristicUUID)], for: service)
                }
            }
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                
                if characteristic.uuid == CBUUID(string: SBrick.QuickDriveCharacteristicUUID) {
                    quickDriveCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
                if characteristic.uuid == CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID) {
                    remoteControlCommandsCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
                if quickDriveCharacteristic != nil && remoteControlCommandsCharacteristic != nil {
                    DispatchQueue.main.async {
                        self.delegate?.sbrickReady(self)
                    }
                }
                
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error.localizedDescription)")
            return
        }
        
//        guard characteristic.uuid == CBUUID(string: SBrick.RemoteControlCommandsCharacteristicUUID) else { return }        
        
        if let data = characteristic.value {
            parse(bytes: [UInt8](data))
        }
        
        DispatchQueue.main.async {
            self.delegate?.sbrick(self, didRead: characteristic.value)
        }
    }
    
    private func parse(bytes: [UInt8]) {
        
        var sectionFirstIndex: Int = 0
        var sectionLastIndex: Int = 0
        var sectionBytes = [UInt8]()
        
        for index in 0..<bytes.count {
            
            if index == sectionFirstIndex {
                sectionLastIndex = index +  Int(bytes[index])
            }
            else {
                sectionBytes.append(bytes[index])
                
                if index == sectionLastIndex {
                    parse(record: sectionBytes)
                    sectionBytes = []
                    sectionFirstIndex = index + 1
                }
            }
        }
    }
    
    private func parse(record sectionBytes: [UInt8]) {
        
        guard sectionBytes.count > 0 else { return }
        
        let recordIdentifier = sectionBytes[0]
        var bytes = sectionBytes
        bytes.remove(at: 0) //remove first byte (record identifier)
        
        //print("record: \(recordIdentifier) bytes: \(bytes)")
        
        switch recordIdentifier {
            
        //04 Command response
        //  04 <1: return code > <n-2: return value >
        case 4:
            guard bytes.count > 0 else { return }
            let returnCode = bytes[0]
            
            //00: Successful operation
            //01: Invalid data length
            //02: Invalid parameter
            //03: No such command
            //04: No authentication needed
            //05: Authentication error
            //06: Authentication needed
            //08: Thermal protection is active
            //09: The system is in a state where the command does not make sense
            
            switch returnCode {
            case 0:
                //print("Successful operation")
                break
                
            default:
                break
            }
            
            
        //06 Voltage measurement
        //  06 < measurement data >
        case 6:
            self.channelValues.removeAll()
            while bytes.count > 1 {
                
                let data = Data(bytes: Array(bytes[0...1]))
                let value = UInt16(littleEndian: data.withUnsafeBytes { $0.pointee })
//                print("ADC channel value: \(value) voltage: \(Double(value) * 0.83875 / 2047.0)")
                
                self.channelValues.append(value)
                
                bytes.removeSubrange(0...1)
            }
            
        default:
            break
        }
        
    }
    
}
