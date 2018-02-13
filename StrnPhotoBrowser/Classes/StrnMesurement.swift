//
//  StrnMesurement.swift
//  StrnPhotoBrowser
//
//

import Foundation
import UIKit

struct StrnMesurement {
    static let isPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    static let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    static var statusBarH: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    static var screenScale: CGFloat {
        return UIScreen.main.scale
    }
    static var screenRatio: CGFloat {
        return screenWidth / screenHeight
    }
}
