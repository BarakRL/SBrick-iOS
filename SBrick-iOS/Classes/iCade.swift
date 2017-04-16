//
//  iCade.swift
//  SBrick-iOS
//
//  Created by Barak Harel on 4/3/17.
//  Copyright © 2017 Barak Harel. All rights reserved.
//

import UIKit

public enum iCadeButtons: String {
    case upPressed =        "w"
    case upReleased =       "e"
    case downPressed =      "x"
    case downReleased =     "z"
    case leftPressed =      "a"
    case leftReleased =     "q"
    case rightPressed =     "d"
    case rightReleased =    "c"
    case button1Pressed =   "h"
    case button1Released =  "r"
    case button2Pressed =   "u"
    case button2Released =  "f"
    case button3Pressed =   "y"
    case button3Released =  "t"
    case button4Pressed =   "j"
    case button4Released =  "n"
    case button5Pressed =   "k"
    case button5Released =  "p"
    case button6Pressed =   "i"
    case button6Released = "m"
    case startPressed =     "o"
    case startReleased =    "g"
    case selectPressed =    "l"
    case selectReleased =   "v"
    
    public static let allValues = [upPressed, upReleased,
                                   downPressed, downReleased,
                                   leftPressed, leftReleased,
                                   rightPressed, rightReleased,
                                   button1Pressed, button1Released,
                                   button2Pressed, button2Released,
                                   button3Pressed, button3Released,
                                   button4Pressed, button4Released,
                                   button5Pressed, button5Released,
                                   button6Pressed, button6Released,
                                   startPressed, startReleased,
                                   selectPressed, selectReleased
                                   ]
}

public class iCade: NSObject {
    
    public class func keyCommands(action: Selector) -> [UIKeyCommand]? {
        
        var keyCommands: [UIKeyCommand] = []
        
        for key in iCadeButtons.allValues {
            keyCommands.append(UIKeyCommand(input: key.rawValue, modifierFlags: [], action: action))
        }
        
        return keyCommands
    }
}
