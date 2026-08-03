//
//  String+Extensions.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/8/2.
//

import Foundation

extension String {
    /// 空字符串转为 nil，用于可选字段（如教师、组名）的空白归一化
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
