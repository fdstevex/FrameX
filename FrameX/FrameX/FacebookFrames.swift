//
//  FacebookFrames.swift
//
//  This is a wrapper for the Facebook set of device frames, and the offsets.json file that's included
//  with them. You can find these on Github here:
//  
//  https://github.com/fastlane/frameit-frames (mirrored https://github.com/fdstevex/frameit-frames)
//
//  Created by Steve Tibbett on 2016-12-27.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//

import Foundation
import CoreGraphics
import AppKit

/**
 * Class to parse the Facebook device frames.
 * Currently expects the downloaded frames to be at deviceFramesPath
 */
struct FacebookFrames {
    struct OffsetInfo {
        // Device key from the offsets.png, for example, "iPhone 6s"
        let deviceName: String
        
        // Offset from frame origin where the screenshot shoudl be placed
        let offset: CGSize
        
        // Width of the screenshot (height would be proportional)
        let width: CGFloat
    }
    
    struct FrameInfo {
        // Path to the device frame PNG
        let frameURL:URL
        
        // Offset information for this frame
        let offsetInfo: OffsetInfo
    }
    
    var frames = [FrameInfo]()
    
    init(deviceFramesPath: String) throws {
        let relativePath = deviceFramesPath
        let resolvedPath = NSString(string: relativePath).expandingTildeInPath
        let offsets = try readOffsets(path: resolvedPath)
        frames = try correlateFiles(path: resolvedPath, offsets: offsets)
    }

    // Correlate the files on disk with the entries in the offsets.json file.
    func correlateFiles(path: String, offsets: [OffsetInfo]) throws -> [FrameInfo] {
        let framesURL = URL(fileURLWithPath: path)

        let fileNames = try FileManager.default.contentsOfDirectory(atPath: framesURL.path)
        
        var frames = [FrameInfo]()
        
        for fileName in fileNames {
            let imageURL = framesURL.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath:imageURL.path) {
                // Use a substring match to find the OffsetInfo
                let baseName = imageURL.lastPathComponent
                for offsetInfo in offsets {
                    if baseName.range(of: offsetInfo.deviceName) != nil {
                        let frameInfo = FrameInfo(frameURL: imageURL, offsetInfo: offsetInfo)
                        frames.append(frameInfo)
                    }
                }
            }
            
        }
        return frames
    }
    
    func readOffsets(path: String) throws -> [OffsetInfo] {
        let frames = try readFrames(path: path)
        return try parseOffsets(path: path, frameDict: frames)
    }
    
    func parseOffsets(path: String, frameDict: [String: Any]) throws -> [OffsetInfo] {
        let offsets = try readFrames(path: path)
        
        var frames = [OffsetInfo]()
        
        for key in offsets.keys {
            if let dict = offsets[key] as? [String: AnyObject] {
                if let offsetString = dict["offset"] as? String {
                    if let width = dict["width"] as? NSNumber {
                        
                        let offsetComponents = offsetString.components(separatedBy: "+")

                        let offsetx = (offsetComponents[1] as NSString).floatValue
                        let offsety = (offsetComponents[2] as NSString).floatValue
                        
                        let offset = CGSize(width: CGFloat(offsetx), height: CGFloat(offsety))
                        let frame = OffsetInfo(deviceName: key, offset: offset, width: CGFloat(width))
                        frames.append(frame)
                    }
                }
            }
        }
        
        return frames
    }
    
    // Read the JSON offset file, return a [String: Dictionary] where the dictionary looks
    // like this:
    //  "iPhone SE": {
    //      "offset": "+64+237",
    //      "width": 640
    //  }
    func readFrames(path: String) throws -> [String: Any] {
        let jsonPath = URL(fileURLWithPath: path).appendingPathComponent("offsets.json")
        let data = try Data.init(contentsOf: jsonPath)
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let root = json as? [String: Any] {
            if let portrait = root["portrait"] as? [String: Any] {
                return portrait
            } else {
                throw NSError()
            }
        } else {
            throw NSError()
        }
    }
}

