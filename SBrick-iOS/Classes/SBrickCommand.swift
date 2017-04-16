//
//  SBrickCommand.swift
//  Pods
//
//  Created by Barak Harel on 11/04/2017.
//
//

import Foundation

public enum SBrickCommand {
    
    case drive(channelId: UInt8, cw: Bool, power: UInt8)
    case stop(channelId: UInt8)
    case getBrickID
    case getWatchDog
    case queryADC(channelId: UInt8)
    case write(bytes: [UInt8])
    
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
