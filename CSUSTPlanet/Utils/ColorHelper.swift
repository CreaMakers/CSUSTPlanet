//
//  ColorHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/22.
//

import Foundation
import SwiftUI

class ColorHelper {
    static let gradeRanges = [
        (range: "90-100", min: 90, max: 100, point: 4.0),
        (range: "85-89", min: 85, max: 89, point: 3.7),
        (range: "82-84", min: 82, max: 84, point: 3.3),
        (range: "78-81", min: 78, max: 81, point: 3.0),
        (range: "75-77", min: 75, max: 77, point: 2.7),
        (range: "72-74", min: 72, max: 74, point: 2.3),
        (range: "68-71", min: 68, max: 71, point: 2.0),
        (range: "64-67", min: 64, max: 67, point: 1.5),
        (range: "60-63", min: 60, max: 63, point: 1.0),
        (range: "≤59", min: 0, max: 59, point: 0.0)
    ]

    static func dynamicColor(grade: Double) -> Color {
        return Color(dynamicUIColor(grade: grade))
    }

    static func dynamicUIColor(grade: Double) -> UIColor {
        let failingThreshold = 60.0
        let midThreshold = 78.0
        let excellentThreshold = 90.0

        let lowColor = UIColor.systemRed
        let midColor = UIColor.systemYellow
        let highColor = UIColor.systemGreen

        if grade < failingThreshold {
            return lowColor
        } else if grade < midThreshold {
            let factor = (grade - failingThreshold) / (midThreshold - failingThreshold)
            return interpolate(from: lowColor, to: midColor, with: CGFloat(factor))
        } else if grade < excellentThreshold {
            let factor = (grade - midThreshold) / (excellentThreshold - midThreshold)
            return interpolate(from: midColor, to: highColor, with: CGFloat(factor))
        } else {
            return highColor
        }
    }

    static func dynamicColor(point: Double) -> Color {
        return Color(dynamicUIColor(point: point))
    }

    static func dynamicUIColor(point: Double) -> UIColor {
        let failingThreshold = 1.0
        let midThreshold = 3.0
        let excellentThreshold = 4.0

        let lowColor = UIColor.systemRed
        let midColor = UIColor.systemYellow
        let highColor = UIColor.systemGreen

        if point < failingThreshold {
            return lowColor
        } else if point < midThreshold {
            let factor = (point - failingThreshold) / (midThreshold - failingThreshold)
            return interpolate(from: lowColor, to: midColor, with: CGFloat(factor))
        } else if point < excellentThreshold {
            let factor = (point - midThreshold) / (excellentThreshold - midThreshold)
            return interpolate(from: midColor, to: highColor, with: CGFloat(factor))
        } else {
            return highColor
        }
    }

    private static func interpolate(from fromColor: UIColor, to toColor: UIColor, with factor: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        fromColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)

        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        toColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)

        let newR = fromR + (toR - fromR) * factor
        let newG = fromG + (toG - fromG) * factor
        let newB = fromB + (toB - fromB) * factor
        let newA = fromA + (toA - fromA) * factor

        return UIColor(red: newR, green: newG, blue: newB, alpha: newA)
    }

    static func electricityColor(electricity: Double) -> Color {
        switch electricity {
        case ..<10: return .red
        case 10 ..< 30: return .orange
        default: return .green
        }
    }
}
