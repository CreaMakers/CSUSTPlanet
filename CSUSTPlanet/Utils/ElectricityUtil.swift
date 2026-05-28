//
//  ElectricityUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/18.
//

import CSUSTKit
import Foundation

enum ElectricityUtilError: LocalizedError {
    case campusNotFound
    case buildingNotFound
    case roomNotFound

    var errorDescription: String? {
        switch self {
        case .campusNotFound:
            return "未找到校区"
        case .buildingNotFound:
            return "未找到楼栋"
        case .roomNotFound:
            return "未找到宿舍"
        }
    }
}

enum ElectricityUtil {
    static let recentHistoryMonths = 3

    static func recentRecordsStartDate(referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: -recentHistoryMonths, to: referenceDate) ?? referenceDate
    }

    static func getExhaustionInfo(from records: [ElectricityRecordGRDB]) -> String? {
        guard !records.isEmpty else { return nil }
        guard let predictionDate = predictExhaustionDate(from: records) else { return nil }
        guard predictionDate > Date() else { return nil }

        return "预计\(predictionDate.formatted(.relative(presentation: .named)))电量耗尽"
    }

    static func predictExhaustionDate(from records: [ElectricityRecordGRDB]) -> Date? {
        // 至少需要两个点才能做线性拟合
        guard records.count >= 2 else { return nil }
        // 截取最后一次“充电”后的数据段
        // 策略：从后往前遍历，如果发现当前项电量大于前一项，说明此处是充电后的起点
        var lastSegment: [ElectricityRecordGRDB] = []
        var i = records.count - 1

        while i >= 0 {
            lastSegment.insert(records[i], at: 0)
            if i > 0 && records[i].electricity > records[i - 1].electricity {
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

    static func downsample(from records: [ElectricityRecordGRDB], to threshold: Int) -> [ElectricityRecordGRDB] {
        let dataCount = records.count

        // 如果数据量本身小于等于阈值，直接返回原数据
        guard threshold > 0, dataCount > threshold else { return records }
        if threshold <= 2 {
            return [records.first, records.last].compactMap { $0 }
        }

        var sampled: [ElectricityRecordGRDB] = []
        sampled.reserveCapacity(threshold)

        sampled.append(records[0])

        let bucketSize = Double(dataCount - 2) / Double(threshold - 2)

        var lastSelectedStep = 0

        for i in 0..<(threshold - 2) {
            let bucketStart = Int(floor(Double(i) * bucketSize)) + 1
            let bucketEnd = Int(floor(Double(i + 1) * bucketSize)) + 1

            let nextBucketStart = Int(floor(Double(i + 1) * bucketSize)) + 1
            let nextBucketEnd = min(Int(floor(Double(i + 2) * bucketSize)) + 1, dataCount)

            var avgX: Double = 0
            var avgY: Double = 0
            if nextBucketStart < dataCount {
                let count = Double(nextBucketEnd - nextBucketStart)
                for j in nextBucketStart..<nextBucketEnd {
                    avgX += records[j].date.timeIntervalSince1970
                    avgY += records[j].electricity
                }
                avgX /= count
                avgY /= count
            } else {
                avgX = records[dataCount - 1].date.timeIntervalSince1970
                avgY = records[dataCount - 1].electricity
            }

            let pointA = records[lastSelectedStep]
            let pointAX = pointA.date.timeIntervalSince1970
            let pointAY = pointA.electricity

            var maxArea: Double = -1
            var selectedIndex = bucketStart

            for j in bucketStart..<min(bucketEnd, dataCount) {
                let area = abs(
                    (pointAX * (records[j].electricity - avgY) + records[j].date.timeIntervalSince1970 * (avgY - pointAY) + avgX * (pointAY - records[j].electricity))
                )

                if area > maxArea {
                    maxArea = area
                    selectedIndex = j
                }
            }

            sampled.append(records[selectedIndex])
            lastSelectedStep = selectedIndex
        }

        sampled.append(records[dataCount - 1])

        return sampled
    }

    static func chartYDomain(
        for records: [ElectricityRecordGRDB],
        padding: Double = 2,
        minimumSpan: Double = 1,
        fallback: ClosedRange<Double> = 0...2
    ) -> ClosedRange<Double> {
        guard let minValue = records.map(\.electricity).min(), let maxValue = records.map(\.electricity).max() else {
            return fallback
        }

        let lowerBound = max(0, minValue - padding)
        let upperBound = max(lowerBound + minimumSpan, maxValue + padding)

        return lowerBound...upperBound
    }

    static func getBuildings(
        _ campusCardHelper: CampusCardHelper,
        _ campus: CampusCardHelper.Campus,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> [CampusCardHelper.Building] {
        if useCache, let buildings = MMKVHelper.ElectricityUtil.buildingsCache[campus] {
            return buildings
        }

        let buildings =
            if let retryProvider {
                try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                    try await campusCardHelper.getBuildings(campus: campus)
                }
            } else {
                try await campusCardHelper.getBuildings(campus: campus)
            }

        MMKVHelper.ElectricityUtil.buildingsCache[campus] = buildings

        return buildings
    }

    static func getRooms(
        _ campusCardHelper: CampusCardHelper,
        _ building: CampusCardHelper.Building,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> [CampusCardHelper.Room] {
        if useCache, let rooms = MMKVHelper.ElectricityUtil.roomsCache[building] {
            return rooms
        }

        let rooms =
            if let retryProvider {
                try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                    try await campusCardHelper.getRooms(building: building)
                }
            } else {
                try await campusCardHelper.getRooms(building: building)
            }

        MMKVHelper.ElectricityUtil.roomsCache[building] = rooms

        return rooms
    }

    static func getElectricity(
        _ campusCardHelper: CampusCardHelper,
        campusName: String,
        buildingName: String,
        roomName: String,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> Double {
        guard let campus = CampusCardHelper.Campus(rawValue: campusName) else {
            throw ElectricityUtilError.campusNotFound
        }

        let buildings = try await getBuildings(campusCardHelper, campus, useCache: useCache, retryProvider: retryProvider)
        guard let building = buildings.first(where: { $0.name == buildingName }) else {
            throw ElectricityUtilError.buildingNotFound
        }

        let rooms = try await getRooms(campusCardHelper, building, useCache: useCache, retryProvider: retryProvider)
        guard let room = rooms.first(where: { $0.name == roomName }) else {
            throw ElectricityUtilError.roomNotFound
        }

        return if let retryProvider {
            try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                try await campusCardHelper.getElectricity(room: room)
            }
        } else {
            try await campusCardHelper.getElectricity(room: room)
        }
    }
}

extension MMKVHelper {
    enum ElectricityUtil {
        @MMKVStorage(key: "ElectricityUtil.buildingsCache", defaultValue: [:])
        static var buildingsCache: [CampusCardHelper.Campus: [CampusCardHelper.Building]]

        @MMKVStorage(key: "ElectricityUtil.roomsCache", defaultValue: [:])
        static var roomsCache: [CampusCardHelper.Building: [CampusCardHelper.Room]]
    }
}
