//
//  MMKVManager.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import CSUSTKit
import Foundation
import MMKV

struct Cached<T: Codable>: Codable {
    let cachedAt: Date
    let value: T
}

// MARK: - Properties

class MMKVManager {
    static let shared = MMKVManager()

    private init() {}

    private var defaultMMKV: MMKV?

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return encoder
    }()

    private let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return decoder
    }()
}

// MARK: - Methods

extension MMKVManager {
    func setup() {
        guard let mmkvDirectoryURL = Constants.mmkvDirectoryURL else {
            fatalError("Failed to get MMKV directory URL")
        }
        MMKV.initialize(rootDir: mmkvDirectoryURL.path)
        guard let defaultMMKV = MMKV(mmapID: Constants.mmkvID) else {
            fatalError("Failed to initialize MMKV with ID: \(Constants.mmkvID)")
        }
        self.defaultMMKV = defaultMMKV
    }

    func close() {
        guard let defaultMMKV = defaultMMKV else { return }
        defaultMMKV.sync()
        defaultMMKV.close()
        self.defaultMMKV = nil
    }

    func clearAll() {
        defaultMMKV?.clearAll()
    }
    
    func sync() {
        defaultMMKV?.sync()
    }
}

// MARK: - Setters

extension MMKVManager {
    func set(forKey key: String, _ value: String) {
        defaultMMKV?.set(value, forKey: key)
    }

    func set(forKey key: String, _ value: Int) {
        defaultMMKV?.set(Int64(value), forKey: key)
    }

    func set(forKey key: String, _ value: Bool) {
        defaultMMKV?.set(value, forKey: key)
    }

    func set(forKey key: String, _ value: Float) {
        defaultMMKV?.set(value, forKey: key)
    }

    func set(forKey key: String, _ value: Double) {
        defaultMMKV?.set(value, forKey: key)
    }

    func set(forKey key: String, _ value: Data) {
        defaultMMKV?.set(value, forKey: key)
    }

    func set<Type: Encodable>(forKey key: String, _ value: Type) {
        if let data = try? jsonEncoder.encode(value) {
            defaultMMKV?.set(data, forKey: key)
        }
    }
}

// MARK: - Getters

extension MMKVManager {
    func string(forKey key: String) -> String? {
        defaultMMKV?.string(forKey: key)
    }

    func int(forKey key: String) -> Int? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        if defaultMMKV.contains(key: key) {
            return Int(defaultMMKV.int64(forKey: key))
        }
        return nil
    }

    func bool(forKey key: String) -> Bool? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        if defaultMMKV.contains(key: key) {
            return defaultMMKV.bool(forKey: key)
        }
        return nil
    }

    func float(forKey key: String) -> Float? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        if defaultMMKV.contains(key: key) {
            return defaultMMKV.float(forKey: key)
        }
        return nil
    }

    func double(forKey key: String) -> Double? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        if defaultMMKV.contains(key: key) {
            return defaultMMKV.double(forKey: key)
        }
        return nil
    }

    func data(forKey key: String) -> Data? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        return defaultMMKV.data(forKey: key)
    }

    func object<Type: Decodable>(forKey key: String, as type: Type.Type) -> Type? {
        guard let defaultMMKV = defaultMMKV else { return nil }
        guard let data = defaultMMKV.data(forKey: key) else {
            return nil
        }
        return try? jsonDecoder.decode(type, from: data)
    }
}

// MARK: - GlobalVars

extension MMKVManager {
    var appearance: String {
        get { string(forKey: "GlobalVars.appearance") ?? "system" }
        set { set(forKey: "GlobalVars.appearance", newValue) }
    }

    var isUserAgreementAccepted: Bool {
        get { bool(forKey: "GlobalVars.isUserAgreementAccepted") ?? false }
        set { set(forKey: "GlobalVars.isUserAgreementAccepted", newValue) }
    }

    var isElectricityTermAccepted: Bool {
        get { bool(forKey: "GlobalVars.isElectricityTermAccepted") ?? false }
        set { set(forKey: "GlobalVars.isElectricityTermAccepted", newValue) }
    }
}

// MARK: - Cached

extension MMKVManager {
    var courseGradesCache: Cached<[EduHelper.CourseGrade]>? {
        get { object(forKey: "Cached.courseGradesCache", as: Cached<[EduHelper.CourseGrade]>.self) }
        set { set(forKey: "Cached.courseGradesCache", newValue) }
    }

    var urgentCoursesCache: Cached<UrgentCourseData>? {
        get { object(forKey: "Cached.urgentCoursesCache", as: Cached<UrgentCourseData>.self) }
        set { set(forKey: "Cached.urgentCoursesCache", newValue) }
    }

    var examSchedulesCache: Cached<[EduHelper.Exam]>? {
        get { object(forKey: "Cached.examSchedulesCache", as: Cached<[EduHelper.Exam]>.self) }
        set { set(forKey: "Cached.examSchedulesCache", newValue) }
    }

    var courseScheduleCache: Cached<CourseScheduleData>? {
        get { object(forKey: "Cached.courseScheduleCache", as: Cached<CourseScheduleData>.self) }
        set { set(forKey: "Cached.courseScheduleCache", newValue) }
    }
}
