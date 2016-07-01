//
//  StringUtil.swift
//  SwiftColorPlugin
//
//  Created by xiyuan_fengyu on 16/6/21.
//  Copyright © 2016年 xiyuan. All rights reserved.
//

import AppKit

struct Regex {
    
    private let rg: NSRegularExpression?
    
    init(str: String) {
        do {
            try rg = NSRegularExpression(pattern: str, options: NSRegularExpressionOptions.CaseInsensitive)
        }
        catch {
            rg = nil
        }
    }
    
    func match(input: String) -> Range<Int>? {
        if let matchs = rg?.matchesInString(input, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, input.characters.count)) {
            if(matchs.count > 0) {
                return matchs[0].range.toRange()!
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    func matchs(input: String) -> [Range<Int>]? {
        if let matchs = rg?.matchesInString(input, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, input.characters.count)) {
            if(matchs.count > 0) {
                return matchs.map{$0.range.toRange()!}
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
}

extension Int {
    
    var toHex: String {
        get {
            return String(self, radix: 16, uppercase: false)
        }
    }
    
    func toHex(minLength: Int) -> String {
        let hex = self.toHex
        let hexLen = hex.characters.count
        return (hexLen < minLength ? String(count: minLength - hexLen, repeatedValue: Character("0")) : "") + hex
    }
    
    var toBinary: String {
        get {
            return String(self, radix: 2, uppercase: false)
        }
    }
    
    func toBinary(minLength: Int) -> String {
        let binary = self.toBinary
        let binaryLen = binary.characters.count
        return (binaryLen < minLength ? String(count: minLength - binaryLen, repeatedValue: Character("0")) : "") + binary
    }
    
}

extension String {
    
    subscript(range: Range<Int>) -> String {
        get {
            let start = self.startIndex.advancedBy(range.startIndex)
            let end = self.startIndex.advancedBy(range.endIndex)
            return self[start..<end]
        }
    }
    
    func match(str: String) -> Bool {
        let regex = Regex(str: str)
        return regex.match(self) != nil
    }
    
    func find(str: String) -> String {
        let regex = Regex(str: str)
        if let matchResult = regex.match(self) {
            return self[matchResult]
        }
        else {
            return ""
        }
    }
    
    var toColor: NSColor {
        get {
            if self.match("^(#|0x|0X|)([0-9a-fA-F]{2,2}){3,4}$") {
                var colorStr = self.find("([0-9a-fA-F]{2,2}){3,4}$")
                if colorStr.characters.count == 6 {
                    colorStr = "ff" + colorStr
                }
                var a: UInt32 = 255
                var r: UInt32 = 255
                var g: UInt32 = 255
                var b: UInt32 = 255
                NSScanner(string: colorStr[0...1]).scanHexInt(&a)
                NSScanner(string: colorStr[2...3]).scanHexInt(&r)
                NSScanner(string: colorStr[4...5]).scanHexInt(&g)
                NSScanner(string: colorStr[6...7]).scanHexInt(&b)
                
                return NSColor.init(red: CGFloat(Float(r) / 255.0), green: CGFloat(Float(g) / 255.0), blue: CGFloat(Float(b) / 255.0), alpha: CGFloat(Float(a) / 255.0))
            }
            else {
                return NSColor.clearColor()
            }
        }
    }

}