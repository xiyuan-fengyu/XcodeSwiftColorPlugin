//
//  SwiftColorPlugin.swift
//
//  Created by xiyuan_fengyu on 16/6/21.
//  Copyright © 2016年 xiyuan. All rights reserved.
//

import AppKit

var sharedPlugin: SwiftColorPlugin?

class SwiftColorPlugin: NSObject, ColorWellDelegate {

    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()

    // MARK: - Initialization

    class func pluginDidLoad(bundle: NSBundle) {
        let allowedLoaders = bundle.objectForInfoDictionaryKey("me.delisa.XcodePluginBase.AllowedLoaders") as! Array<String>
        if allowedLoaders.contains(NSBundle.mainBundle().bundleIdentifier ?? "") {
            sharedPlugin = SwiftColorPlugin(bundle: bundle)
        }
    }

    init(bundle: NSBundle) {
        self.bundle = bundle

        super.init()
        // NSApp may be nil if the plugin is loaded from the xcodebuild command line tool
        if (NSApp != nil && NSApp.mainMenu == nil) {
            center.addObserver(self, selector: #selector(self.applicationDidFinishLaunching), name: NSApplicationDidFinishLaunchingNotification, object: nil)
        } else {
            initializeAndLog()
        }
    }

    private func initializeAndLog() {
        let name = bundle.objectForInfoDictionaryKey("CFBundleName")
        let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString")
        let status = initialize() ? "loaded successfully" : "failed to load"
        NSLog("🔌 Plugin \(name) \(version) \(status)")
    }

    func applicationDidFinishLaunching() {
        center.removeObserver(self, name: NSApplicationDidFinishLaunchingNotification, object: nil)
        initializeAndLog()
    }

    // MARK: - Implementation

    func initialize() -> Bool {

        addSelectionWatcher()
        return true
    }

    private var textView: NSTextView!
    
    private var colorWell: ColorWell = ColorWell()
    
    private var colorFrame: ColorFrame = ColorFrame()
    
    private var curColorRange: NSRange?
    
    func addSelectionWatcher() {
        colorWell.addObserver(self, forKeyPath: "color", options: NSKeyValueObservingOptions.New, context: nil)
        colorWell.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.selectionDidChanged), name: NSTextViewDidChangeSelectionNotification, object: nil)
        
        if self.textView === nil {
            if let firstResponder = NSApp.keyWindow?.firstResponder {
                if firstResponder.isKindOfClass(NSClassFromString("DVTSourceTextView")!) && firstResponder.isKindOfClass(NSTextView.self) {
                    self.textView = firstResponder as! NSTextView
                }
            }
        }
        else {
            let notification = NSNotification(name: NSTextViewDidChangeSelectionNotification, object: self.textView)
            self.selectionDidChanged(notification)
        }
        
    }
    
    func onColorChanged(newColor: NSColor) {
        if curColorRange != nil && textView !== nil {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            newColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            var newColorStr = "\"#"
            if a != 1 {
                newColorStr += Int(255 * Float(a)).toHex(2)
            }
            newColorStr += Int(255 * Float(r)).toHex(2)
            newColorStr += Int(255 * Float(g)).toHex(2)
            newColorStr += Int(255 * Float(b)).toHex(2)
            newColorStr += "\".toColor"
            
            let str = textView.string!
            
            let location = curColorRange!.location
            let length = curColorRange!.length
            let replaceRange = Range<String.Index>(str.startIndex.advancedBy(location)..<str.startIndex.advancedBy(location + length))
            textView.string?.replaceRange(replaceRange, with: newColorStr)
            
            textView.setSelectedRange(NSMakeRange(location, 0))
        }
    }
    
    func selectionDidChanged(notifiction: NSNotification)
    {
        if let firstResponder = notifiction.object {
            if firstResponder.isKindOfClass(NSClassFromString("DVTSourceTextView")!) && firstResponder.isKindOfClass(NSTextView.self) {
                self.textView = firstResponder as! NSTextView
                
                matchColor()
            }
        }
    }
    
    func matchColor() {
        if self.textView !== nil {
            let text = NSString(string: self.textView.textStorage!.string)
            
            let selectedRange: NSRange = self.textView.selectedRange()
            
            if selectedRange.length > 0 {
                return
            }
            
            let lineRange = text.lineRangeForRange(selectedRange)
            
            
//            let selectedRangeInLine = NSMakeRange(selectedRange.location - lineRange.location, selectedRange.length)
            let line = text.substringWithRange(lineRange)
            if let matchResult = matchColor(line, location: selectedRange.location - lineRange.location) {
                let colorRange = matchResult.0
                let matchedColor = matchResult.1
                let backgroundColor = self.textView.backgroundColor.colorUsingColorSpace(NSColorSpace.genericRGBColorSpace())
                
                var r: CGFloat = 1.0
                var g: CGFloat = 1.0
                var b: CGFloat = 1.0
                backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: nil)
                let backgroundLuminance = (r + g + b) / 3.0
                
                let strokeColor = (backgroundLuminance > 0.5) ? NSColor.grayColor() : NSColor.whiteColor()

                let selectedColorRange = NSMakeRange(lineRange.location + colorRange.location, colorRange.length)
                curColorRange = selectedColorRange
                
//                print(selectedRange)
//                print(lineRange)
//                print(selectedColorRange)
                
                let selectionRectOnScreen = self.textView.firstRectForCharacterRange(selectedColorRange, actualRange: nil)
                let selectionRectInWindow = self.textView.window?.convertRectFromScreen(selectionRectOnScreen)
                let selectionRectInView = self.textView.convertRect(selectionRectInWindow!, fromView: nil)
                let colorWellRect = NSMakeRect(NSMaxX(selectionRectInView) - 49, NSMinY(selectionRectInView) - selectionRectInView.size.height - 2, 50, selectionRectInView.size.height + 2)
                
                self.colorWell.color = matchedColor
                self.colorWell.strokeColor = strokeColor
                self.colorWell.frame = NSIntegralRect(colorWellRect)
                self.textView.addSubview(self.colorWell)
                
                self.colorFrame.frame = NSInsetRect(NSIntegralRect(selectionRectInView), -1, -1)
                self.colorFrame.strokeColor = strokeColor
                self.textView.addSubview(self.colorFrame)

            }
            else {
                self.colorWell.removeFromSuperview()
                self.colorFrame.removeFromSuperview()
                
                curColorRange = nil
            }
        }
    }
    
    func matchColor(line: String, location: Int) -> (NSRange, NSColor)? {
        let colorRegexStr = "(#|0x|0X|)([0-9a-fA-F]{2,2}){3,4}"
        if let matchs = Regex(str: "\"\(colorRegexStr)\"\\.toColor").matchs(line) {
            if matchs.count == 1 {
                return (NSMakeRange(matchs[0].startIndex, matchs[0].count), line[matchs[0]].find(colorRegexStr).toColor)
            }
            else {
                for m in matchs {
                    if location >= m.startIndex && location < m.startIndex + m.count {
                        return (NSMakeRange(m.startIndex, m.count), line[m].find(colorRegexStr).toColor)
                    }
                }
                return (NSMakeRange(matchs[0].startIndex, matchs[0].count), line[matchs[0]].find(colorRegexStr).toColor)
            }
        }
        return nil
    }
    
    
    func showAlert(msg: String) {
        let alert = NSAlert()
        alert.messageText = msg
        alert.runModal()
    }
}

