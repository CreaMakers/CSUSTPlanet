//
//  ExamSchedule.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/4.
//

import CSUSTKit
import Foundation
import SwiftData

struct ExamScheduleData: Codable {
    var exams: [EduHelper.Exam]
    var lastUpdated: Date

    static func fromExams(exams: [EduHelper.Exam]) -> ExamScheduleData {
        return ExamScheduleData(exams: exams, lastUpdated: .now)
    }

    static func empty() -> ExamScheduleData {
        return ExamScheduleData(exams: [], lastUpdated: .now)
    }
}

@Model
class ExamSchedule {
    var data: ExamScheduleData = ExamScheduleData.empty()

    init(data: ExamScheduleData) {
        self.data = data
    }
}
