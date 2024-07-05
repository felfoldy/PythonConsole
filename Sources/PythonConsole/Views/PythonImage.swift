//
//  PythonImage.swift
//  
//
//  Created by Tibor Felföldy on 2024-07-05.
//

import Foundation
import SwiftUI

extension Image {
    static var python: Image? {
        guard let path = Bundle.module.path(forResource: "python", ofType: "png") else {
            return nil
        }

        #if canImport(UIKit)
        if let img = UIImage(contentsOfFile: path) {
            return Image(uiImage: img)
        }
        #endif
        
        #if canImport(AppKit)
        if let img = NSImage(contentsOfFile: path) {
            return Image(nsImage: img)
        }
        #endif
        
        return nil
    }
}
