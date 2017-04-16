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
import AVFoundation

class ViewController: UIViewController, SBrickManagerDelegate, SBrickDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    var manager: SBrickManager!
    var sbrick: SBrick?
    
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
        self.sbrick = sbrick
    }
    
    func sbrickDisconnected(_ sbrick: SBrick) {
        statusLabel.text = "SBrick disconnected :("
        self.sbrick = nil
    }
    
    enum State {
        case idle
        case driving
        case stopped
        case reversing
    }
    
    var didReverseCW = false
    var state = State.idle {
        
        didSet {
            
            guard let sbrick = self.sbrick else { return }
            
            switch state {
                
            case .idle:
                sbrick.send(command: .stop(channelId: 0x02))
                sbrick.send(command: .stop(channelId: 0x03))
                
            case .driving:
                self.didReverseCW = false
                sbrick.send(command: .drive(channelId: 0x02, cw: false, power: 255))
                
            case .stopped:
                sbrick.send(command: .stop(channelId: 0x02))
                
            case .reversing:
                self.didReverseCW = !self.didReverseCW
                sbrick.send(command: .stop(channelId: 0x02))
                sbrick.send(command: .drive(channelId: 0x03, cw: didReverseCW, power: 255))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                     sbrick.send(command: .drive(channelId: 0x02, cw: true, power: 255))
                })
                
            }
        }
        
    }
    
    func sbrickReady(_ sbrick: SBrick) {
        
        statusLabel.text = "SBrick ready!"
    }
    
    func sbrick(_ sbrick: SBrick, didRead data: Data?) {
        
        guard let data = data else { return }
        print("sbrick [\(sbrick.name)] did read: \([UInt8](data))")        
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


