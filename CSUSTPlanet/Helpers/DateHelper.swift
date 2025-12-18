//
//  DateHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/3.
//

import Foundation

enum DateHelper {
    static func relativeTimeString(for date: Date) -> String {
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 0 {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh_CN")
            f.dateStyle = .short
            f.timeStyle = .short
            return f.string(from: date)
        }

        if seconds < 60 {
            return "刚刚"
        } else if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else if seconds < 172800 {
            let tf = DateFormatter()
            tf.locale = Locale(identifier: "zh_CN")
            tf.dateFormat = "HH:mm"
            return "昨天 " + tf.string(from: date)
        } else if seconds < 7 * 86400 {
            return "\(seconds / 86400)天前"
        } else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh_CN")
            f.dateStyle = .short
            f.timeStyle = .short
            return f.string(from: date)
        }
    }
}
