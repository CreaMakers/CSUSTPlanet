//
//  ElectricityHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/18.
//

import Foundation

final class ElectricityHelper {
    private init() {}

    static func predictExhaustionDate(from records: [ElectricityRecord]) -> Date? {
        // 至少需要两个点才能做线性拟合
        guard records.count >= 2 else { return nil }
        // 确保按时间排序
        let sortedRecords = records.sorted { $0.date < $1.date }
        // 截取最后一次“充电”后的数据段
        // 策略：从后往前遍历，如果发现当前项电量大于前一项，说明此处是充电后的起点
        var lastSegment: [ElectricityRecord] = []
        var i = sortedRecords.count - 1

        while i >= 0 {
            lastSegment.insert(sortedRecords[i], at: 0)
            if i > 0 && sortedRecords[i].electricity > sortedRecords[i - 1].electricity {
                // 发现电量跳变（充电），截断并跳出
                break
            }
            i -= 1
        }

        // 拟合至少需要两个点
        guard lastSegment.count >= 2 else { return nil }

        // 线性回归计算 (y = mx + b)
        // 为了提高计算精度，我们将时间戳（Double）减去第一个点的时间戳，作为 x 轴坐标
        let n = Double(lastSegment.count)
        let firstTimestamp = lastSegment[0].date.timeIntervalSince1970

        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumXX: Double = 0

        for record in lastSegment {
            let x = record.date.timeIntervalSince1970 - firstTimestamp
            let y = record.electricity

            sumX += x
            sumY += y
            sumXY += x * y
            sumXX += x * x
        }

        // 斜率 m 的计算公式: (n*Σxy - Σx*Σy) / (n*Σxx - (Σx)^2)
        let denominator = n * sumXX - sumX * sumX
        if abs(denominator) < 0.000001 { return nil }  // 防止除以 0

        let m = (n * sumXY - sumX * sumY) / denominator

        // 截距 b 的计算公式: (Σy - m*Σx) / n
        let b = (sumY - m * sumX) / n

        // 预测 y = 0 的时间点
        // 0 = m*x + b  =>  x = -b / m
        // 如果斜率 m >= 0，说明电量没在减少，无法预测耗尽时间
        if m >= 0 { return nil }

        let targetX = -b / m
        let predictedTimestamp = firstTimestamp + targetX

        return Date(timeIntervalSince1970: predictedTimestamp)
    }
}
