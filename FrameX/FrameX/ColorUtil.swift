//
//  ColorUtil.swift
//  FrameX
//
//  Created by Steve Tibbett on 2016-12-29.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//

import Foundation
import AppKit

// Adapted from http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios
extension NSColor {
    static func fromHexString (hex:String) -> NSColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return NSColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return NSColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
