//
//  ElectricityBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

import BackgroundTasks
import Foundation
import OSLog

struct ElectricityBackgroundTask: BackgroundTaskProvider {
    var identifier: String { Constants.backgroundElectricityID }

    var interval: TimeInterval { 6 * 60 * 60 }

    func handle(task: BGAppRefreshTask) {
        task.expirationHandler = {
            // TODO: 处理后台任务超时
            Logger.backgroundTaskHelper.debug("后台任务超时: \(self.identifier)")
            task.setTaskCompleted(success: false)
        }
        // TODO: 获取电量
        Logger.backgroundTaskHelper.debug("获取电量")
        task.setTaskCompleted(success: true)
    }
}
