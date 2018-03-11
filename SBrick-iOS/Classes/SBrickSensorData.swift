//
//  SBrickSensorData.swift
//  Pods-SBrick-iOS_Example
//
//  Created by Barak Harel on 3/10/18.
//

import Foundation

public class SBrickSensorData {
    
    public enum SensorType {
        case unknown
        case tilt
        case motion
    }
    
    public let channelA: UInt8
    public let channelB: UInt8
    
    //values
    public let sensorValue: UInt8
    public let sensorType: SensorType
    
    //raw values
    public let referenceVoltage: UInt16
    public let channelAVoltage: UInt16
    public let channelBVoltage: UInt16
    
    public init?(bytes: [UInt8]) {
        
        guard bytes.count == 6 else { return nil }
        
        self.channelA = bytes[2] & 0xF
        self.channelB = bytes[4] & 0xF
        
        self.referenceVoltage = [bytes[0], bytes[1]].uint16littleEndianValue() >> 4
        self.channelAVoltage = [bytes[2], bytes[3]].uint16littleEndianValue() >> 4
        self.channelBVoltage = [bytes[4], bytes[5]].uint16littleEndianValue() >> 4
        
        let typeValue = Double(channelAVoltage) / Double(referenceVoltage)
        let sensorValue = Double(channelBVoltage) / Double(referenceVoltage)
        
        //convert to UInt8
        self.sensorValue = UInt8(clamping: Int(Double(UInt8.max) * sensorValue))
        
        //guess sensor type, see:
        //https://social.sbrick.com/forums/topic/511/wedo-sensor-raw-value-voltage-questions/view/post_id/5149
        
        if typeValue > 0.15 && typeValue < 0.25 {
            self.sensorType = .tilt
        }
        else if typeValue > 0.35 && typeValue < 0.45 {
            self.sensorType = .motion
        }
        else {
            self.sensorType = .unknown
        }
    }
    
}
