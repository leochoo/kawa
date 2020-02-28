//
//  HyperlinkTextField.swift
//  kawa
//
//  Created by utatti on 06/08/2015.
//  Copyright (c) 2015-2016 utatti and project contributors.
//  Licensed under the MIT License.
//

import Cocoa

// 이건 뭐 하는 클래스지???
// 텍스트를 하이퍼링크로써 변환시켜주는 것인가? 

class HyperlinkTextField: NSTextField {
    // System Settings  안쪽에 github 링크를 hyperlink화 시킬 때 쓰인다.
    func setURL(_ url: URL) {
        self.allowsEditingTextAttributes = true
        self.isSelectable = true
        self.attributedStringValue = linkString(stringValue, url: url)
    }

    // 얘는 어디에서도 안 부르는 것 같은 데 여튼 커서 관련인가봐
    override func resetCursorRects() {
        self.addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }

    // 위에 setURL 에서 부르는 데 이걸로 hyperlink를 생성.
    func linkString(_ text: String, url: URL) -> NSMutableAttributedString {
        let attrString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: attrString.length)
        attrString.beginEditing()
        attrString.addAttribute(NSAttributedString.Key.link, value: url.absoluteString, range: range)
        attrString.addAttribute(NSAttributedString.Key.font, value: font!, range: range)
        attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: NSColor.blue, range: range)
        attrString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue as AnyObject, range: range)
        attrString.endEditing()
        return attrString
    }
}
