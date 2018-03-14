//
//  SBrickPort.swift
//  Pods
//
//  Created by Barak Harel on 5/19/17.
//
//

import Foundation

public enum SBrickPort: Int, Codable {
    
    case port1 = 1
    case port2 = 2
    case port3 = 3
    case port4 = 4
    
    public var writeChannel: UInt8 {
        
        switch self {
        case .port1: return 0x00
        case .port2: return 0x01
        case .port3: return 0x02
        case .port4: return 0x03
        }
    }
    
    public var readChannelA: UInt8 {
        
        switch self {
        case .port1: return 0x00
        case .port2: return 0x02
        case .port3: return 0x04
        case .port4: return 0x06
        }
    }
    
    public var readChannelB: UInt8 {
        
        switch self {
        case .port1: return 0x01
        case .port2: return 0x03
        case .port3: return 0x05
        case .port4: return 0x07
        }
    }
}

public class SBrickManagedPort {
    
    public var drivePowerThreshold: UInt8 = 8
    
    public let port: SBrickPort
    public private(set) var command: SBrickCommand
    
    public var isDriving: Bool {
        
        switch self.command {
        case .stop(_): return false
        case .drive(_, _, let power): return power > 0
        default: return false
        }
    }
    
    internal var commandDidChange: Bool = false
    
    init(port: SBrickPort) {
        self.port = port
        self.command = .stop(channelId: port.writeChannel)
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
        
        if commandDidChange {
            self.command = .stop(channelId: port.writeChannel)
        }
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
        
        if commandDidChange {
            self.command = .drive(channelId: port.writeChannel, cw: isCW, power: power)
        }
    }
}
