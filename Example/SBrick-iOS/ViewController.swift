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
    
    
    var adcTimer: Timer?
    func startAutodrive() {
        
        guard let sbrick = self.sbrick else { return }
        
        sbrick.send(command: .write(bytes: [0x2C,0x01]))
        
        adcTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
            
            guard let _self = self else { return }
            guard let sbrick = _self.manager.sbricks.first else { return }
            
            
            sbrick.send(command: .queryADC(channelId: 0x01)) { (bytes) in
                
                let adcValue = bytes.uint16littleEndianValue()/16
                
                print("ADC 01: \(adcValue)")
                
                if adcValue > 250 && _self.state == .idle {
                    _self.state = .driving
                    
                }
                else if adcValue < 250 && _self.state != .reversing {
                    _self.state = .reversing
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        _self.state = .idle
                    })
                }
            }
        })
    }
    
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
    
    var accPower: UInt8 = 0
    var accTimer: Timer?
    
    var player: AVAudioPlayer?
    func playSound(name soundName: String, withExtension ext: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            print("url not found")
            return
        }
        
        do {
            /// this codes for making this app ready to takeover the device audio
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
                        
            player!.play()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
        player?.stop()
    }
}

extension ViewController {
    
    open override var keyCommands: [UIKeyCommand]? {
        return iCade.keyCommands(action: #selector(keyPress(sender:)))
    }
    
    func keyPress(sender: UIKeyCommand) {
        
        guard let sbrick = self.sbrick else { return }
        
        if let key = iCadeButtons(rawValue: sender.input) {
            
            switch key {
            case .upPressed:
                print("UP pressed")
            case .upReleased:
                print("UP released")
                
            case .downPressed:
                print("DOWN pressed")
            case .downReleased:
                print("DOWN released")
                
            case .leftPressed:
                print("LEFT pressed")
                sbrick.send(command: .drive(channelId: 3, cw: true, power: 255))
                
            case .leftReleased:
                print("LEFT released")
                sbrick.send(command: .stop(channelId: 3))
                
            case .rightPressed:
                print("RIGHT pressed")
                sbrick.send(command: .drive(channelId: 3, cw: false, power: 255))
                
            case .rightReleased:
                print("RIGHT released")
                sbrick.send(command: .stop(channelId: 3))
                
            case .button1Pressed:
                print("BUTTON 1 pressed")
                sbrick.send(command: .drive(channelId: 2, cw: false, power: 0xFF))
                
            case .button1Released:
                print("BUTTON 1 released")
                sbrick.send(command: .stop(channelId: 2))
                
            case .button2Pressed:
                print("BUTTON 2 pressed")
                //sbrick.send(command: .drive(channelId: 2, cw: false, power: 0x80))
                
                accPower = 100
                accTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self] (timer) in
                    if self.accPower < 0xFF {
                        self.accPower = UInt8(min(Int(self.accPower) + 10, 0xFF))
                        sbrick.send(command: .drive(channelId: 2, cw: false, power: self.accPower))
                    }
                })
                
            case .button2Released:
                print("BUTTON 2 released")
                sbrick.send(command: .stop(channelId: 2))
                accTimer?.invalidate()
                
            case .button3Pressed:
                print("BUTTON 3 pressed")
                sbrick.send(command: .drive(channelId: 2, cw: true, power: 0xFF))
                
            case .button3Released:
                print("BUTTON 3 released")
                sbrick.send(command: .stop(channelId: 2))
                
            case .button4Pressed:
                print("BUTTON 4 pressed")
//                sbrick.send(command: .drive(channelId: 2, cw: true, power: 0x80))
                accPower = 100
                accTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self] (timer) in
                    if self.accPower < 0xFF {
                        self.accPower = UInt8(min(Int(self.accPower) + 10, 0xFF))
                        sbrick.send(command: .drive(channelId: 2, cw: true, power: self.accPower))
                    }
                })
                
            case .button4Released:
                print("BUTTON 4 released")
                sbrick.send(command: .stop(channelId: 2))
                accTimer?.invalidate()
                
            case .button5Pressed:
                print("BUTTON 5 pressed")
                playSound(name: "horn", withExtension: "wav")
            case .button5Released:
                print("BUTTON 5 released")
                stopSound()
                
            case .button6Pressed:
                print("BUTTON 6 pressed")
                playSound(name: "engine", withExtension: "mp3")
            case .button6Released:
                print("BUTTON 6 released")
                stopSound()
                
            case .startPressed:
                print("START pressed")
                
                if adcTimer == nil {
                    startAutodrive()
                }
                else {
                    adcTimer?.invalidate()
                    adcTimer = nil
                    sbrick.send(command: .stop(channelId: 2))
                }
                
                
            case .startReleased:
                print("START released")
                
            case .selectPressed:
                print("SELECT pressed")
            case .selectReleased:
                print("SELECT released")
            }
        }
    }
}

