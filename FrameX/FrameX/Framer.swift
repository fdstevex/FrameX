//
//  Framer.swift
//
//  Created by Steve Tibbett on 2016-12-31.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreText
import AppKit

// Errors are reported as exceptions, so they need to be granular enough to be understandable.
enum FrameXError: Error {
    case cantFindFrame(frameName:String)
    case cantLoadFrame(framePath:String)
    case cantLoadScreenshot(screenshotPath:String)
    case cantParseHTML(error:String)
    case invalidHTML
    case cantGetImageRef
    case cantCreateImageRepresentation
    case cantCreateContext
    case fontNotFound(name: String)
    case cantParseSize(size: String)
    case missingParameter(name: String)
    case cantParseArgument(argument: String)
    case invalidArgument(argument: String)
    case invalidOutputPath
}

func prepareCaption(_ text: String, request: FrameParams) throws -> NSAttributedString {
    let caption = try NSMutableAttributedString.fromHTML(html: text)
    
    // Add horizontal center attribute
    let centerParagraphStyle = NSMutableParagraphStyle()
    centerParagraphStyle.alignment = .center
    
    let range = NSRange(location: 0, length: caption.length)
    caption.addAttribute(NSParagraphStyleAttributeName, value: centerParagraphStyle, range: range)

    // If we're not using HTML styling then we're applying font and colour to the entire string
    if (!request.styledHTML) {
        // Apply the font
        guard let font = NSFont(name: request.fontName, size: CGFloat(request.fontSize)) else {
            throw FrameXError.fontNotFound(name: request.fontName)
        }
        
        caption.addAttribute(NSFontAttributeName, value:font, range: range)

        // Apply the text colour
        let colour = NSColor.fromHexString(hex: request.textColor)
        caption.addAttribute(NSForegroundColorAttributeName, value:colour, range: range)
    }
    
    return caption
}

func stampImage(request: FrameParams, frame: FacebookFrames.FrameInfo) throws -> NSImage {
    // Make sure we have the parameters we need
    guard let caption = request.caption else {
        throw FrameXError.missingParameter(name: "caption")
    }
    
    guard let screenshotPath = request.screenshotPath else {
        throw FrameXError.missingParameter(name: "screenshotPath")
    }
    
    let width:Int = Int(request.targetSize.width)
    let height:Int = Int(request.targetSize.height)
    let outerRect = CGRect(origin: CGPoint(x: 0, y: 0), size: request.targetSize)
    
    guard let frameImage = NSImage(contentsOf: frame.frameURL) else {
        throw FrameXError.cantLoadFrame(framePath: frame.frameURL.path)
    }
    
    guard let screenshotImage = NSImage(contentsOfFile: screenshotPath) else {
        throw FrameXError.cantLoadScreenshot(screenshotPath: screenshotPath)
    }
    
    // Create the image we're going to draw into
    guard let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bitmapFormat: NSAlphaFirstBitmapFormat, bytesPerRow: 0, bitsPerPixel: 0) else {
        throw FrameXError.cantCreateImageRepresentation
    }
    
    let context = NSGraphicsContext(bitmapImageRep: imageRep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.setCurrent(context)
    
    guard let c = context?.cgContext else {
        throw FrameXError.cantCreateContext
    }
    
    // Fill with background color
    let colour = NSColor.fromHexString(hex: request.backgroundColor)
    c.setFillColor(colour.cgColor)
    c.fill(outerRect)
    
    c.setTextDrawingMode(CGTextDrawingMode.fill)
    c.textMatrix = CGAffineTransform.identity
    
    // Measure the height of the caption
    let string = try prepareCaption(caption, request: request)
    let captionWidth = outerRect.width - CGFloat(request.horizontalTextMargin*2.0)
    let captionHeight = string.height(forWidth: captionWidth) + CGFloat(request.captionTopMargin + request.frameTopMargin)
    
    // Calculate the device frame location, which will be shrunk based on the
    // horizontalFrameMargin, and then moved down based on the height of the caption
    let newFrameWidth = request.targetSize.width - (CGFloat(request.horizontalFrameMargin)*2)
    let newFrameHeight = frameImage.size.height * (newFrameWidth / frameImage.size.width)
    let newFrameSize = CGSize(width:newFrameWidth, height:newFrameHeight)
    
    // Calculate the frame rect
    let frameOrigin = CGPoint(x: CGFloat(request.horizontalFrameMargin), y: (request.targetSize.height-newFrameSize.height) - captionHeight)
    var frameRect = CGRect(origin:frameOrigin, size:newFrameSize)
    
    // Draw the screenshot
    let frameScale = frameRect.width / frameImage.size.width
    
    let screenshotWidth = frame.offsetInfo.width * frameScale
    let screenshotAspect = screenshotImage.size.height / screenshotImage.size.width
    let screenshotSize = CGSize(width: screenshotWidth, height:screenshotWidth * screenshotAspect)
    
    let screenshotOrigin = CGPoint(x: frameOrigin.x + (frame.offsetInfo.offset.width*frameScale), y: frameOrigin.y + frameRect.size.height - (frame.offsetInfo.offset.height * frameScale) - (screenshotSize.height))
    var screenshotRect = CGRect(origin: screenshotOrigin, size: screenshotSize)
    guard let screenshotImageRef = screenshotImage.cgImage(forProposedRect: &screenshotRect, context: nil, hints: nil) else {
        throw FrameXError.cantGetImageRef
    }
    c.draw(screenshotImageRef, in:screenshotRect)
    
    // Draw the frame
    guard let frameImageRef = frameImage.cgImage(forProposedRect: &frameRect, context: nil, hints: nil) else {
        throw FrameXError.cantGetImageRef
    }
    c.draw(frameImageRef, in:frameRect)
    
    // Draw the caption
    let captionRect = CGRect(origin: CGPoint(x: request.horizontalTextMargin, y: -request.captionTopMargin), size: CGSize(width:captionWidth, height:request.targetSize.height))
    string.draw(rect: captionRect, context: c)
    
    NSGraphicsContext.restoreGraphicsState()
    
    let image = NSImage(size: request.targetSize)
    image.addRepresentation(imageRep)
    return image
}

// Find the named frame in the FacebookFrames offsets collection
func findFrame(_ frameName: String, deviceFramesPath: String) throws -> FacebookFrames.FrameInfo {
    let facebookFrames = try FacebookFrames(deviceFramesPath: deviceFramesPath)
    var frameInfo: FacebookFrames.FrameInfo?
    for f in facebookFrames.frames {
        if (f.frameURL.lastPathComponent.range(of: frameName) != nil) {
            frameInfo = f
            break
        }
    }
    
    guard let result = frameInfo else {
        // Couldn't find a frame to use
        throw FrameXError.cantFindFrame(frameName: frameName)
    }
    
    return result
}
