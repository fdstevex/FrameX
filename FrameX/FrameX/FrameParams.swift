//
//  FrameParams.swift
//  FrameX
//
//  Created by Steve Tibbett on 2016-12-31.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//

import Foundation

// Parameters used when processing a screenshot.
// Typically provided as command line arguments.
struct FrameParams {
    
    // The size of image to create; required
    var targetSize = CGSize.zero
    
    // Path to the source screenshot
    var screenshotPath: String?
    
    // Path to the Facebook device frames (directory containing png files and offsets.json)
    // Default path is where Fastlane Frameit puts them, handy if the user uses that.
    var deviceFramesPath = "~/.frameit/devices_frames_2/latest"
    
    // Output path and filename, including .png extension; if not specified, default is
    // the base name with "_framed" appended to it.
    var outputPath: String?
    
    // Name of the frame from the Facebook Frames set to use, for 
    // example, "Apple iPhone 5c Red"
    var frameName: String?
    
    var backgroundColor = "#a5d9ff"
    
    // If styledHTML is true, then the fontName, fontSize and textColor are not applied.
    // In that case, style is be expected to be specified in the caption as HTML.
    // For example:
    //      <span style='font-size: 55pt; font-family: Lato; color: green'>
    //       <b>Plan</b> <span style='color: yellow'>a week's meals in 5 minutes!</span>
    //      </span>
    
    var caption: String?
    var styledHTML = false
    var fontName = "Helvetica Neue Light"
    var fontSize = 50.0
    var textColor = "#333333"
    
    // Layout properties
    var horizontalFrameMargin = 50.0
    var horizontalTextMargin = 50.0
    var captionTopMargin = 40.0
    var frameTopMargin = 40.0
}

extension FrameParams {
    // Pass in the command line arguments, get back a FrameParams
    static func fromArgs(_ args: [String]) throws -> FrameParams {
        var result = FrameParams()
        
        func valuePart(_ arg: String) throws -> String {
            let range = arg.range(of: "=")
            if (range == nil || range!.isEmpty) {
                throw FrameXError.cantParseArgument(argument:arg)
            }
            return arg.substring(from: arg.index(after: range!.lowerBound))
        }

        func doubleValue(_ arg: String) throws -> Double {
            guard let value = Double(arg) else {
                throw FrameXError.cantParseArgument(argument:arg)
            }
            return value
        }
        
        func stringToCGSize(_ str: String) throws -> CGSize {
            let components = str.components(separatedBy: "x")
            guard components.count == 2 else {
                throw FrameXError.cantParseSize(size: str)
            }
            
            guard let width = Float(components[0]), let height = Float(components[1]) else {
                throw FrameXError.cantParseSize(size: str)
            }
            return CGSize(width: CGFloat(width), height: CGFloat(height))
        }

        // Loop through the arguments, updating the result structure with specified parameters
        for arg in args {
            if arg.hasPrefix("--html") {
                result.styledHTML = true
                continue
            }

            if (arg.hasPrefix("--screenshotPath")) {
                result.screenshotPath = try valuePart(arg);
                continue;
            }

            if (arg.hasPrefix("--outputPath")) {
                result.outputPath = try valuePart(arg);
                continue;
            }

            if (arg.hasPrefix("--deviceFramesPath")) {
                result.deviceFramesPath = try valuePart(arg);
                continue;
            }

            
            if (arg.hasPrefix("--frameName")) {
                result.frameName = try valuePart(arg);
                continue;
            }
            
            if (arg.hasPrefix("--targetSize")) {
                result.targetSize = try stringToCGSize(valuePart(arg))
                continue
            }

            if (arg.hasPrefix("--caption")) {
                result.caption = try valuePart(arg)
                continue
            }

            if (arg.hasPrefix("--textColor")) {
                result.textColor = try valuePart(arg)
                continue
            }

            if (arg.hasPrefix("--backgroundColor")) {
                result.backgroundColor = try valuePart(arg)
                continue
            }

            if (arg.hasPrefix("--fontName")) {
                result.fontName = try valuePart(arg)
                continue
            }

            if (arg.hasPrefix("--fontSize")) {
                result.fontSize = try doubleValue(valuePart(arg))
                continue
            }

            if (arg.hasPrefix("--horizontalFrameMargin")) {
                result.horizontalFrameMargin = try doubleValue(valuePart(arg))
                continue
            }
            
            if (arg.hasPrefix("--horizontalTextMargin")) {
                result.horizontalTextMargin = try doubleValue(valuePart(arg))
                continue
            }

            if (arg.hasPrefix("--captionTopMargin")) {
                result.captionTopMargin = try doubleValue(valuePart(arg))
                continue
            }

            if (arg.hasPrefix("--frameTopMargin")) {
                result.frameTopMargin = try doubleValue(valuePart(arg))
                continue
            }

            throw FrameXError.invalidArgument(argument: arg)
        }
        
        try result.validate()
        return result
    }
    
    func validate() throws {
        if (targetSize.width == 0 || targetSize.height == 0) {
            throw FrameXError.missingParameter(name: "targetSize")
        }
        
        if (screenshotPath == nil) {
            throw FrameXError.missingParameter(name: "screenshotPath")
        }

        if (frameName == nil) {
            throw FrameXError.missingParameter(name: "frameName")
        }
    }
}
