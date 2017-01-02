//
//  AttributedStringMeasure.swift
//  FrameX
//
//  Created by Steve Tibbett on 2016-12-31.
//  Copyright © 2016 Fall Day Software Inc. All rights reserved.
//

import Foundation
import AppKit

extension NSMutableAttributedString {
    static func fromHTML(html: String) throws -> NSMutableAttributedString {
        guard let data = html.data(using: .utf8) else {
            throw FrameXError.invalidHTML
        }
        do {
            let string = try NSMutableAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
                                                       documentAttributes: nil)
            
            return string
        } catch let error as NSError {
            throw FrameXError.cantParseHTML(error: error.description)
        }
    }
}

extension NSAttributedString {
    func height(forWidth:CGFloat) -> CGFloat {
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        let box = CGRect(origin: CGPoint.zero, size: CGSize(width:forWidth, height:CGFloat(LONG_MAX)))
        let startIndex: CFIndex = 0
        let path = CGMutablePath()
        path.addRect(box)
        
        // Create a frame for this column and draw it.
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location:startIndex, length:0), path, nil)
        
        // Start the next frame at the first character not visible in this frame.
        let lineArray = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lineArray)
        
        var totalHeight = CGFloat(0.0), ascent = CGFloat(0.0), descent = CGFloat(0.0), leading = CGFloat(0.0)
        
        var lastDescent = CGFloat(0.0)
        
        for j in 0..<lineCount {
            let currentLine = unsafeBitCast(CFArrayGetValueAtIndex(lineArray, j), to: CTLine.self)
            CTLineGetTypographicBounds(currentLine, &ascent, &descent, &leading)
            totalHeight += ascent + descent + leading
            lastDescent = descent
        }
        
        totalHeight -= lastDescent
        
        return totalHeight
    }
    
    func draw(rect:CGRect, context: CGContext) {
        let framesetter = CTFramesetterCreateWithAttributedString(self)
        let startIndex: CFIndex = 0
        let path = CGMutablePath()
        path.addRect(rect)
        
        // Create a frame for this column and draw it.
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location:startIndex, length:0), path, nil)
        CTFrameDraw(frame, context)
    }
}

