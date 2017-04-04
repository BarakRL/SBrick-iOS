//
//  SBrickManager.swift
//  SBrickTest
//
//  Created by Barak Harel on 4/3/17.
//  Copyright © 2017 Barak Harel. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol SBrickManagerDelegate: class {
    func sbrickManager(_ sbrickManager: SBrickManager, didDiscover sbrick: SBrick)
    func sbrickManager(_ sbrickManager: SBrickManager, didUpdateBluetoothState bluetoothState: CBManagerState)
}

class SBrickManager: NSObject, CBCentralManagerDelegate {
            
    private var centralManager:CBCentralManager!
    var sbricks = [SBrick]()
    
    weak var delegate: SBrickManagerDelegate?
    
    init(delegate: SBrickManagerDelegate) {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        
        case .poweredOn:
            
            if shouldStartDiscovery {
                startDiscovery()
            }
            
        default:
            break
            
        }
                
        delegate?.sbrickManager(self, didUpdateBluetoothState: central.state)
        
    }
    
    var shouldStartDiscovery: Bool = false
    func startDiscovery() {
        
        print("Starting discovery")
        
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            shouldStartDiscovery = true
        }
    }
    
    func stopDiscovery() {
        
        print("Stopping discovery")
        
        shouldStartDiscovery = false
        centralManager.stopScan()
    }
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     */
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let sbrick = SBrick(peripheral: peripheral, advertisementData: advertisementData) {
            
            DispatchQueue.main.async {
                
                for sbrick in self.sbricks {
                    if sbrick.peripheral == peripheral {
                        //already added
                        return
                    }
                }
                
                self.add(sbrick: sbrick)
                self.delegate?.sbrickManager(self, didDiscover: sbrick)
            }
        }
    }
    
    private func add(sbrick: SBrick) {
        
        print("Found SBrick NAME: \(sbrick.name)")
        print("SBrick UUID: \(sbrick.peripheral.identifier)")
        
        sbricks.append(sbrick)
    }
    
    func connect(to sbrick: SBrick) {
        // Request a connection to the peripheral
        centralManager.connect(sbrick.peripheral, options: nil)
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SBRICK!!!")        
        
        for sbrick in sbricks {
            if sbrick.peripheral == peripheral {
                sbrick.didConnect()
            }
        }
    }
    
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SBRICK FAILED!!!")
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("**** DISCONNECTED FROM SBRICK!!!")
        
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        
        for sbrick in sbricks {
            if sbrick.peripheral == peripheral {
                sbrick.didDisconnect()
                sbricks.remove(object: sbrick)
            }
        }
        
    }
    
    
}

extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}
