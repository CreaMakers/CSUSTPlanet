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
        Logger.backgroundTaskHelper.debug("注册全部后台任务成功")
    }

    func schedule(provider: BackgroundTaskProvider) {
        let request = BGAppRefreshTaskRequest(identifier: provider.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: provider.interval)
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.backgroundTaskHelper.debug("调度后台任务成功: \(provider.identifier)")
        } catch {
            Logger.backgroundTaskHelper.error("调度后台任务失败: \(error)")
        }
    }

    func scheduleAllTasks() {
        tasks.forEach { schedule(provider: $0) }
        Logger.backgroundTaskHelper.debug("调度全部后台任务成功")
    }

    func cancel(provider: BackgroundTaskProvider) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: provider.identifier)
        Logger.backgroundTaskHelper.debug("取消后台任务: \(provider.identifier)")
    }

    func cancelAllTasks() {
        tasks.forEach { cancel(provider: $0) }
        Logger.backgroundTaskHelper.debug("取消全部后台任务")
    }
}
