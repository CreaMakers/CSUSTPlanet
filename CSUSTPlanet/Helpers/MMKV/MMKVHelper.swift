//
//  MMKVHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import CSUSTKit
import Combine
import Foundation
import OSLog
import os

#if !WIDGET
import MMKV
#else
import MMKVAppExtension
#endif

// MARK: - MMKVHelper

final class MMKVHelper {
    static let shared = MMKVHelper()

    private init() {}

    private let logHandler = LogHandler()

    lazy var mmkv: MMKV = {
        let mmkvDirectoryURL = Constants.mmkvDirectoryURL

        MMKV.initialize(rootDir: mmkvDirectoryURL.path, logLevel: .info, handler: self.logHandler)
        guard
            let instance = MMKV(
                mmapID: Constants.mmkvID,
                cryptKey: nil,
                rootPath: mmkvDirectoryURL.path,
                mode: .multiProcess,
                expectedCapacity: 0
            )
        else {
            fatalError("Failed to initialize MMKV with ID: \(Constants.mmkvID)")
        }

        return instance
    }()

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NAN")
        return encoder
    }()

    private let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NAN")
        return decoder
    }()

    fileprivate func removeValue(forKey key: String) {
        mmkv.removeValue(forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: String) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Int) {
        mmkv.set(Int64(value), forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Bool) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Float) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Double) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Data) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set<Type: Encodable>(forKey key: String, _ value: Type) {
        if let data = try? jsonEncoder.encode(value) {
            mmkv.set(data, forKey: key)
        }
    }

    fileprivate func string(forKey key: String) -> String? {
        mmkv.string(forKey: key)
    }

    fileprivate func int(forKey key: String) -> Int? {
        if mmkv.contains(key: key) {
            return Int(mmkv.int64(forKey: key))
        }
        return nil
    }

    fileprivate func bool(forKey key: String) -> Bool? {
        if mmkv.contains(key: key) {
            return mmkv.bool(forKey: key)
        }
        return nil
    }

    fileprivate func float(forKey key: String) -> Float? {
        if mmkv.contains(key: key) {
            return mmkv.float(forKey: key)
        }
        return nil
    }

    fileprivate func double(forKey key: String) -> Double? {
        if mmkv.contains(key: key) {
            return mmkv.double(forKey: key)
        }
        return nil
    }

    fileprivate func data(forKey key: String) -> Data? {
        return mmkv.data(forKey: key)
    }

    fileprivate func object<Type: Decodable>(forKey key: String, as type: Type.Type) -> Type? {
        guard let data = mmkv.data(forKey: key) else {
            return nil
        }
        return try? jsonDecoder.decode(type, from: data)
    }
}

// MARK: - MMKVValueType

protocol MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Self?
    func write(to helper: MMKVHelper, key: String)
}

extension String: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> String? { helper.string(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Bool: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Bool? { helper.bool(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Int: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Int? { helper.int(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Double: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Double? { helper.double(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Data: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Data? { helper.data(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Array: MMKVValueType where Element: Codable {
    static func read(from helper: MMKVHelper, key: String) -> Array? { return helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Dictionary: MMKVValueType where Key: Codable, Value: Codable {
    static func read(from helper: MMKVHelper, key: String) -> Dictionary? { return helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Date: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Date? {
        guard let timeInterval = helper.double(forKey: key) else { return nil }
        return Date(timeIntervalSince1970: timeInterval)
    }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self.timeIntervalSince1970) }
}

extension Cached: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Cached? { helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension CampusCardHelper.Campus: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Self? {
        guard let rawValue = helper.string(forKey: key) else { return nil }
        return Self(rawValue: rawValue)
    }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self.rawValue) }
}

// MARK: - MMKVIPCNotifier

final class MMKVIPCNotifier {
    static let shared = MMKVIPCNotifier()

    private let lock = OSAllocatedUnfairLock()

    #if !WIDGET
    private var subjects: [String: PassthroughSubject<Void, Never>] = [:]
    #endif

    private init() {}

    #if WIDGET
    func notifyChange(forKey key: String) {
        let name = "\(Constants.mmkvIPCPrefix).\(key)" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name),
            nil,
            nil,
            true
        )
        Logger.mmkvIPCNotifier.info("发送MMKV跨进程通知 - Key: \(key)")
    }
    #else
    func subject(forKey key: String) -> PassthroughSubject<Void, Never> {
        lock.withLock {
            if let existingSubject = subjects[key] {
                return existingSubject
            }

            let newSubject = PassthroughSubject<Void, Never>()
            subjects[key] = newSubject

            let name = "\(Constants.mmkvIPCPrefix).\(key)" as CFString
            let observer = Unmanaged.passUnretained(self).toOpaque()

            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                observer,
                Self.darwinNotificationCallback,
                name,
                nil,
                .deliverImmediately
            )

            return newSubject
        }
    }

    private static let darwinNotificationCallback: CFNotificationCallback = { _, observer, name, _, _ in
        guard let name = name?.rawValue as? String,
            let observerInfo = observer
        else { return }

        let changedKey = name.replacingOccurrences(of: "\(Constants.mmkvIPCPrefix).", with: "")
        let instance = Unmanaged<MMKVIPCNotifier>.fromOpaque(observerInfo).takeUnretainedValue()

        let subjectToTrigger = instance.lock.withLock {
            instance.subjects[changedKey]
        }

        subjectToTrigger?.send(())
        Logger.mmkvIPCNotifier.info("接收到MMKV跨进程通知 - Key: \(changedKey)")
    }
    #endif
}

// MARK: - MMKVStorage

@propertyWrapper
final class MMKVStorage<T: MMKVValueType> {
    let key: String
    let defaultValue: T

    private let subject: CurrentValueSubject<T, Never>
    private let lock = OSAllocatedUnfairLock()

    #if !WIDGET
    private var cancellables = Set<AnyCancellable>()
    #endif

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue

        let initialValue = T.read(from: MMKVHelper.shared, key: key) ?? defaultValue
        self.subject = CurrentValueSubject<T, Never>(initialValue)

        #if !WIDGET
        MMKVIPCNotifier.shared.subject(forKey: key)
            .sink { [weak self] in
                guard let self else { return }
                let newValue = T.read(from: MMKVHelper.shared, key: key) ?? self.defaultValue
                self.subject.send(newValue)
            }
            .store(in: &cancellables)
        #endif
    }

    var wrappedValue: T {
        get { T.read(from: MMKVHelper.shared, key: key) ?? defaultValue }
        set {
            lock.withLock {
                newValue.write(to: MMKVHelper.shared, key: key)
                subject.send(newValue)
            }

            #if WIDGET
            MMKVIPCNotifier.shared.notifyChange(forKey: key)
            #endif
        }
    }

    var projectedValue: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
}

@propertyWrapper
final class MMKVOptionalStorage<T: MMKVValueType> {
    let key: String

    private let subject: CurrentValueSubject<T?, Never>
    private let lock = OSAllocatedUnfairLock()

    #if !WIDGET
    private var cancellables = Set<AnyCancellable>()
    #endif

    init(key: String) {
        self.key = key
        self.subject = CurrentValueSubject(T.read(from: MMKVHelper.shared, key: key))

        #if !WIDGET
        MMKVIPCNotifier.shared.subject(forKey: key)
            .sink { [weak self] in
                guard let self else { return }
                let newValue = T.read(from: MMKVHelper.shared, key: key)
                self.subject.send(newValue)
            }
            .store(in: &cancellables)
        #endif
    }

    var wrappedValue: T? {
        get { T.read(from: MMKVHelper.shared, key: key) }
        set {
            lock.withLock {
                if let value = newValue {
                    value.write(to: MMKVHelper.shared, key: key)
                } else {
                    MMKVHelper.shared.removeValue(forKey: key)
                }
                subject.send(newValue)

                #if WIDGET
                MMKVIPCNotifier.shared.notifyChange(forKey: key)
                #endif
            }
        }
    }

    var projectedValue: AnyPublisher<T?, Never> {
        subject.eraseToAnyPublisher()
    }
}

extension Logger {
    #if WIDGET
    static let mmkv = Logger(widgetCategory: "MMKV")
    #else
    static let mmkv = Logger(appCategory: "MMKV")
    #endif
    static let mmkvIPCNotifier = Logger(appCategory: "MMKVIPCNotifier")
}
