//
//  InputSourceManager.swift
//  kawa
//
//  Created by utatti on 27/07/2015.
//  Copyright (c) 2015-2017 utatti and project contributors.
//  Licensed under the MIT License.
//

import Carbon
import Cocoa

class InputSource: Equatable { // 어떠한 값이 동일한 지 비교할 수 있는 타입
    // == 연산자를 overload 한다 (기존의미 덮어쓰기)
    static func == (lhs: InputSource, rhs: InputSource) -> Bool {
        return lhs.id == rhs.id
    }

    let tisInputSource: TISInputSource
    let icon: NSImage?

    var id: String {
        return tisInputSource.id
    }

    var name: String {
        return tisInputSource.name
    }

    // 한자문화권 언어
    var isCJKV: Bool {
        if let lang = tisInputSource.sourceLanguages.first {
            return lang == "ko" || lang == "ja" || lang == "vi" || lang.hasPrefix("zh")
        }
        return false
    }

    // 클래스 초기값
    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource

        var iconImage: NSImage? = nil

        // 인풋소스에 해당하는 이미지, 즉 언어를 나타내는 아이콘인 듯.
        if let imageURL = tisInputSource.iconImageURL {
            for url in [imageURL.retinaImageURL, imageURL.tiffImageURL, imageURL] {
                if let image = NSImage(contentsOf: url) {
                    iconImage = image
                    break
                }
            }
        }
        // 혹시 인풋소스의 아이콘 이미지가 없으면 iconRef 를 쓰게 예외 처리
        if iconImage == nil, let iconRef = tisInputSource.iconRef {
            iconImage = NSImage(iconRef: iconRef)
        }

        self.icon = iconImage
    }

    // 언어를 선택하는 함수!
    func select() {
        // 인풋소스 선택
        TISSelectInputSource(tisInputSource)

        if isCJKV, let selectPreviousShortcut = InputSourceManager.getSelectPreviousShortcut() {
            // Workaround for TIS CJKV layout bug:
            // when it's CJKV, select nonCJKV input first and then return
            if let nonCJKV = InputSourceManager.nonCJKVSource() {
                nonCJKV.select()
                InputSourceManager.selectPrevious(shortcut: selectPreviousShortcut)
            }
        }
    }
}

// 인풋소스 관리자 클래스
class InputSourceManager {
    // 인풋소스들 리스트
    static var inputSources: [InputSource] = []

    // 첫 실행
    static func initialize() {
        // 어레이에 모든 인풋소스 언어들 불러오기
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        // 리스트로 변환
        let inputSourceList = inputSourceNSArray as! [TISInputSource]
        // 인풋소스 중 선택 가능한 것만 뽑아서 inputSources에 넣음.
        inputSources = inputSourceList.filter({
            // closure 함수의 첫 parameter $0
            // 근데 여기서 어떤게 함수인지 잘 모르겠다.
            $0.category == TISInputSource.Category.keyboardInputSource && $0.isSelectable
        }).map { InputSource(tisInputSource: $0) }
    }
    
    static func nonCJKVSource() -> InputSource? {
        return inputSources.first(where: { !$0.isCJKV })
    }

    // 이걸로 전 언어를 선택 함
    // CG어쩌구 라이브러리를 좀 더 봐야겠다.
    static func selectPrevious(shortcut: (Int, UInt64)) {
        let src = CGEventSource(stateID: .hidSystemState)

        let key = CGKeyCode(shortcut.0)
        let flag = CGEventFlags(rawValue: shortcut.1)

        let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)!
        let up = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)!

        down.flags = flag;
        up.flags = flag;

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    // from read-symbolichotkeys script of Karabiner
    // github.com/tekezo/Karabiner/blob/master/src/util/read-symbolichotkeys/read-symbolichotkeys/main.m
    // select() 함수에서 불림
    static func getSelectPreviousShortcut() -> (Int, UInt64)? {
        guard let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.symbolichotkeys") else {
            return nil
        }
        guard let symbolichotkeys = dict["AppleSymbolicHotKeys"] as! NSDictionary? else {
            return nil
        }
        guard let symbolichotkey = symbolichotkeys["60"] as! NSDictionary? else {
            return nil
        }
        if (symbolichotkey["enabled"] as! NSNumber).intValue != 1 {
            return nil
        }
        guard let value = symbolichotkey["value"] as! NSDictionary? else {
            return nil
        }
        guard let parameters = value["parameters"] as! NSArray? else {
            return nil
        }
        return (
            (parameters[1] as! NSNumber).intValue,
            (parameters[2] as! NSNumber).uint64Value
        )
    }
}

// 이걸로 로컬파일에 있는 이미지를 엑세스 하는 데, 거기에 좀 커스텀을 더한 듯.
private extension URL {
    var retinaImageURL: URL {
        var components = pathComponents
        let filename: String = components.removeLast()
        let ext: String = pathExtension
        let retinaFilename = filename.replacingOccurrences(of: "." + ext, with: "@2x." + ext)
        return NSURL.fileURL(withPathComponents: components + [retinaFilename])!
    }

    var tiffImageURL: URL {
        return deletingPathExtension().appendingPathExtension("tiff")
    }
}
