//
//  HomeViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import RealmSwift

@MainActor
class HomeViewModel: ObservableObject {
    @Published var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?
    @Published var examScheduleData: Cached<[EduHelper.Exam]>?
    @Published var courseScheduleData: Cached<CourseScheduleData>?
    @Published var urgentCourseData: Cached<UrgentCourseData>?
    @Published var electricityDorms: [Dorm] = []
    @Published var totalElectricityDorms: Int = 0
    @Published var todayCourses: [CourseDisplayInfo] = []

    // MARK: - DEBUG时间处理
    private var currentTime: Date {
        // #if DEBUG
        //     // let formatter = DateFormatter()
        //     // formatter.dateFormat = "yyyy-MM-dd HH:mm"
        //     // return formatter.date(from: "2025-09-18 17:38") ?? Date()
        // #else
        return Date()
        // #endif
    }

    func loadData() {
        gradeAnalysisData = MMKVManager.shared.courseGradesCache
        examScheduleData = MMKVManager.shared.examSchedulesCache
        courseScheduleData = MMKVManager.shared.courseScheduleCache
        urgentCourseData = MMKVManager.shared.urgentCoursesCache

        // 加载宿舍电量数据，按最新记录时间排序，最多取2个
        guard let realm = try? Realm() else { return }
        let dorms = realm.objects(Dorm.self)
        let domsWithRecords = dorms.filter { !($0.records.isEmpty) }  // 只保留有电量记录的宿舍
        totalElectricityDorms = domsWithRecords.count
        electricityDorms =
            domsWithRecords
            .sorted { dorm1, dorm2 in
                let record1 = dorm1.records.max(by: { $0.date < $1.date })
                let record2 = dorm2.records.max(by: { $0.date < $1.date })
                return (record1?.date ?? Date.distantPast) > (record2?.date ?? Date.distantPast)
            }
            .prefix(2)
            .map { $0 }

        // 加载今日课程数据
        if let scheduleData = courseScheduleData {
            todayCourses = ScheduleHelper.getUnfinishedCourses(
                for: currentTime,
                in: scheduleData.value,
                maxCount: 5,
                at: currentTime
            )
        }
    }
}
