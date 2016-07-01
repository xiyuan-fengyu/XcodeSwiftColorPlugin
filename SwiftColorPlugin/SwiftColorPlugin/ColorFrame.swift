//
//  ColorFrame.swift
//  SwiftColorPlugin
//
//  Created by xiyuan_fengyu on 16/6/21.
//  Copyright © 2016年 xiyuan. All rights reserved.
//

import AppKit

class ColorFrame: NSView {
    
    var strokeColor: NSColor!
    
    override func drawRect(dirtyRect: NSRect) {
        self.strokeColor.setStroke()
        NSBezierPath.strokeRect(NSInsetRect(self.bounds, 0.5, 0.5))
    }
}
