//
//  ManufacturerData.swift
//  SBrick-iOS
//
//  Created by Barak Harel on 4/3/17.
//  Copyright © 2017 Barak Harel. All rights reserved.
//

import Foundation

public class ManufacturerData {
    
    public private(set) var productId: UInt8 = 0
    public private(set) var hardwareVersion: String = ""
    public private(set) var firmwareVersion: String = ""
    public private(set) var deviceIdentifier: String = ""
    public private(set) var isSecured: Bool = false
    
    internal init?(data: Data) {
        
        let bytes = [UInt8](data)
        guard bytes.count > 2 && bytes[0] == 152 && bytes[1] == 1 else { return nil }
        
        parse(bytes: bytes)
    }
    
    
    private func parse(bytes: [UInt8]) {
        
        var sectionFirstIndex: Int = 2
        var sectionLastIndex: Int = 0 //first section length is 2: [152, 1]
        var sectionBytes = [UInt8]()
        
        //iterate over bytes, break them down to groups of record bytes
        //see: https://social.sbrick.com/wiki/view/pageId/11/slug/the-sbrick-ble-protocol
        
        for index in 2..<bytes.count {
            
            if index == sectionFirstIndex {
                sectionLastIndex = index +  Int(bytes[index])
            }
            else {
                sectionBytes.append(bytes[index])
                
                if index == sectionLastIndex {
                    parse(sectionBytes: sectionBytes)
                    sectionBytes = []
                    sectionFirstIndex = index + 1
                }
            }
        }
    }
    
    private func parse(sectionBytes: [UInt8]) {
        
        guard sectionBytes.count > 0 else { return }
        
        let recordIdentifier = sectionBytes[0]
        var bytes = sectionBytes
        bytes.remove(at: 0) //remove first byte (record identifier)
        
        //print("record: \(recordIdentifier) bytes: \(bytes)")
        
        switch recordIdentifier {
        case 152:
            //header, skip
            break
            
        case 0:
            // 00 Product type
            //     00 <1: Product ID> <2: HW major/minor version> <2: FW major/minor version>
            //         00 - SBrick
            //     Example 1: 02 00 00 - Product SBrick
            //     Example 2: 06 00 00 04 00 04 01 - Product SBrick, HW 4.0, FW 4.1
            
            if bytes.count > 0 {
                self.productId = bytes[0]
            }
            
            if bytes.count >= 3 {
                self.hardwareVersion = "\(bytes[1]).\(bytes[2])"
            }
            
            if bytes.count >= 5 {
                self.firmwareVersion = "\(bytes[3]).\(bytes[4])"
            }
            
        case 1:
            // 01 BlueGiga ADC sensor raw reading
            //     01 <1: channel> <2: raw sensor reading>
            //     Example, battery reading '12f0' on SBrick: 04 01 00 12 F0
            //     Example, temperature reading '12f0': 04 01 0e 12 F0
            
            //TO DO
            break
            
        case 2:
            // 02 Device Identifier
            //     02 < Device identifier string >
            //     Example, SBrick device ID: 07 02 0D 23 FC 19 87 63
            
            self.deviceIdentifier = ""
            for byte in bytes {
                if deviceIdentifier.count > 0 {
                    self.deviceIdentifier += ":"
                }
                self.deviceIdentifier += String(format:"%2X", byte)
            }
            
        case 3:
            // 03 Simple Security status
            //     05 <1: status code >
            //     00: Freely accessible
            //     01: Authentication needed for some functions
            
            if bytes.count > 0 {
                self.isSecured = (bytes[0] != 0)
            }
            
            
        default:
            //TO DO: more defined at spec file
            break
        }
    }
    
}
