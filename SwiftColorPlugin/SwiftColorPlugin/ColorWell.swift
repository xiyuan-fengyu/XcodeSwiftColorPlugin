//
//  ColorWell.swift
//  SwiftColorPlugin
//
//  Created by 123456 on 16/6/21.
//  Copyright © 2016年 xiyuan. All rights reserved.
//

import AppKit

protocol ColorWellDelegate {
    
    func onColorChanged(newColor: NSColor)
    
}

class ColorWell: NSColorWell {
    
    var strokeColor: NSColor!
    
    var oldColor: NSColor!
    
    var delegate: ColorWellDelegate?
    
    override func drawRect(dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        let path = NSBezierPath(roundedRect: NSMakeRect(0, -5, self.bounds.size.width, self.bounds.size.height + 5), xRadius: 5.0, yRadius: 5.0)
        path.addClip()
        self.drawWellInside(self.bounds)
        NSGraphicsContext.restoreGraphicsState()
        
        if self.strokeColor !== nil {
            let strokePath = NSBezierPath(roundedRect: NSInsetRect(NSMakeRect(0, -5, self.bounds.size.width, self.bounds.size.height + 5), 0.5, 0.5), xRadius: 5.0, yRadius: 5.0)
            self.strokeColor.setStroke()
            strokePath.stroke()
        }

    }
    
    override func didChangeValueForKey(key: String) {
        if color != oldColor {
            oldColor = color
            delegate?.onColorChanged(self.color)
        }
    }
    
}
