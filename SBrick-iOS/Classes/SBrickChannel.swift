//
//  SBrickChannel.swift
//  Pods
//
//  Created by Barak Harel on 5/19/17.
//
//

import Foundation

public class SBrickChannel {
    
    public var drivePowerThreshold: UInt8 = 8
    
    public let channelID: UInt8
    public private(set) var command: SBrickCommand
    
    internal var commandDidChange: Bool = false
    
    init(channelID: UInt8) {
        self.channelID = channelID
        self.command = .stop(channelId: channelID)
        self.commandDidChange = false
    }
    
    public func stop() {
        
        //check if updated
        switch self.command {
        case .stop(_):
            break;
            
        default:
            self.commandDidChange = true
        }
        
        self.command = .stop(channelId: channelID)
    }
    
    public func drive(power: UInt8, isCW: Bool) {
        
        //check if updated
        switch self.command {
        case let .drive(_, currentCW, currentpower):
            
            let powerDiff: UInt8 = UInt8(abs(Int(currentpower) - Int(power)))
            if powerDiff > self.drivePowerThreshold || currentCW != isCW {
                self.commandDidChange = true
            }
            
        default:
            self.commandDidChange = true
        }
        
        
        self.command = .drive(channelId: channelID, cw: isCW, power: power)
    }
}
