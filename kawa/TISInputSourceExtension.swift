//
//  TISInputSourceExtension.swift
//  kawa
//
//  Created by Yonguk Jeong on 16/09/2017.
//  Copyright (c) 2017 utatti and project contributors.
//  Licensed under the MIT License.
//

import Foundation

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            // 여기서 가져오는 구나!!!
            // documentation 에도 제대로 안 되어 있어서 그냥 내가 직접 문의함...
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!).takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var name: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }

    var iconImageURL: URL? {
        return getProperty(kTISPropertyIconImageURL) as! URL?
    }

    var iconRef: IconRef? {
        return OpaquePointer(TISGetInputSourceProperty(self, kTISPropertyIconRef)) as IconRef?
    }
}
