//
//  BackgroundTaskHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

import BackgroundTasks
import Foundation
import OSLog

// MARK: - BackgroundTaskProvider

protocol BackgroundTaskProvider {
    var identifier: String { get }
    var interval: TimeInterval { get }
    func handle(task: BGAppRefreshTask)
}

// MARK: - BackgroundTaskHelper

final class BackgroundTaskHelper {
    static let shared = BackgroundTaskHelper()

    private init() {}

    private let tasks: [BackgroundTaskProvider] = [
        GradeBackgroundTask(),
        ElectricityBackgroundTask(),
    ]

    func registerAllTasks() {
        for provider in tasks {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: provider.identifier, using: nil) { task in
                guard let task = task as? BGAppRefreshTask else { return }
                self.schedule(provider: provider)
                provider.handle(task: task)
            }
        }
    }

    func schedule(provider: BackgroundTaskProvider) {
        let request = BGAppRefreshTaskRequest(identifier: provider.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: provider.interval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.backgroundTaskHelper.error("调度后台任务失败: \(error)")
        }
    }

    func scheduleAllTasks() {
        tasks.forEach { schedule(provider: $0) }
    }

    func cancel(provider: BackgroundTaskProvider) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: provider.identifier)
    }

    func cancelAllTasks() {
        tasks.forEach { cancel(provider: $0) }
    }
}

// MARK: - GradeBackgroundTask

struct GradeBackgroundTask: BackgroundTaskProvider {
    var identifier: String { Constants.backgroundGradeID }

    var interval: TimeInterval { 3 * 60 * 60 }

    func handle(task: BGAppRefreshTask) {
        task.expirationHandler = {
            // TODO: 处理后台任务超时
        }
        // TODO: 获取成绩
        task.setTaskCompleted(success: true)
    }
}

// MARK: - ElectricityBackgroundTask

struct ElectricityBackgroundTask: BackgroundTaskProvider {
    var identifier: String { Constants.backgroundElectricityID }

    var interval: TimeInterval { 6 * 60 * 60 }

    func handle(task: BGAppRefreshTask) {
        task.expirationHandler = {
            // TODO: 处理后台任务超时
        }
        // TODO: 获取电量
        task.setTaskCompleted(success: true)
    }
}
