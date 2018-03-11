//
//  SBrickCommand.swift
//  Pods
//
//  Created by Barak Harel on 11/04/2017.
//
//

import Foundation



public enum SBrickCommand: Equatable {
    
    case drive(channelId: UInt8, cw: Bool, power: UInt8)
    case stop(channelId: UInt8)
    case getBrickID
    case getWatchDog
    case queryADC(channelId: UInt8)
    case write(bytes: [UInt8])
    
    case enableSensor(port: SBrickPort) //TO DO: use port instead of channel
    case querySensor(port: SBrickPort)  //TO DO: use port instead of channel
    
    func writeBytes() -> [UInt8] {
        
        switch self {
            
        case .drive(let channelId, let cw, let power):
            return [0x01, channelId, cw ? 0x01: 0x00, power]
            
        case .stop(let channelId):
            return [0x00, channelId]
            
        case .getBrickID:
            return [0x0A]
            
        case .getWatchDog:
            return [0x0E]
            
        case .queryADC(let channelId):
            return [0x0F, channelId]
            
        case .write(let bytes):
            return bytes
            
        case .enableSensor(let port):
            return [0x2C, 0x08, port.readChannelA, port.readChannelB]
            
        case .querySensor(let port):
            return [0x0F, 0x08, port.readChannelA, port.readChannelB]
        }
    }
    
    public static func ==(lhs: SBrickCommand, rhs: SBrickCommand) -> Bool {
        
        switch (lhs, rhs) {
        case (let .drive(channel1, cw1, power1), let .drive(channel2, cw2, power2)):
            return channel1 == channel2 && cw1 == cw2 && power1 == power2
        
        case (let .stop(channel1), let .stop(channel2)):
            return channel1 == channel2
            
        default:
            return false
        }
        
    }
    
}

public typealias SBrickCommandCompletion = (([UInt8])->Void)

internal class SBrickCommandWrapper {
    
    let command: SBrickCommand
    var onComplete: SBrickCommandCompletion?
    
    internal init(command: SBrickCommand, onComplete:SBrickCommandCompletion? = nil) {
        self.command = command
        self.onComplete = onComplete
    }
}
