//
//  main.swift
//  FrameX entry point
//
//  Created by Steve Tibbett on 2016-12-28.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText
import AppKit

// Command line execution starts here

do {
    // Parse the command line arguments into a FrameParams
    var args = CommandLine.arguments
    args.removeFirst()
    var request = try FrameParams.fromArgs(args)
    
    // Find the frame from the Facebook frames collection
    let frame = try findFrame(request.frameName!, deviceFramesPath: request.deviceFramesPath)
    
    // Stamp the image
    let image = try stampImage(request:request, frame:frame)
    if let bits = image.representations.first as? NSBitmapImageRep {
        if let data = bits.representation(using: .PNG, properties: [:]) {
            var outputPath: String?
            if let userSpecifiedPath = request.outputPath {
                outputPath = userSpecifiedPath
            } else if let screenshotPath = request.screenshotPath {
                // Use the screenshotPath appending "_framed" to the base filename
                var url = URL(fileURLWithPath:screenshotPath)
                outputPath = url.deletingPathExtension().path + "_framed.png"
            }
            
            guard let finalOutputPath = outputPath else {
                throw FrameXError.invalidOutputPath
            }
            let dest = URL(fileURLWithPath: finalOutputPath)
            try data.write(to: dest)
        }
    }
} catch {
    // Outermost exception handler
    print("Exception: \(error)")
}



