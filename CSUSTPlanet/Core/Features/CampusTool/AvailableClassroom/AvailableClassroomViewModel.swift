//
//  AvailableClassroomViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/8.
//

import CSUSTKit
import Foundation

@MainActor
final class AvailableClassroomViewModel: ObservableObject {
    @Published var availableClassrooms: [String]? = nil
    @Published var searchText: String = ""

    var filteredAvailableClassrooms: [String]? {
        guard let classrooms = availableClassrooms else { return nil }
        if searchText.isEmpty {
            return classrooms
        } else {
            return classrooms.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    @Published var warningMessage = ""
    @Published var errorMessage = ""

    @Published var isShowingWarning = false
    @Published var isShowingError = false
    @Published var isLoading = false

    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @Published var selectedWeek: Int = 1
    @Published var selectedDayOfWeek: EduHelper.DayOfWeek = .monday
    @Published var selectedSection: Int = 1

    func queryAvailableClassrooms() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    availableClassrooms = try await eduHelper.courseService.getAvailableClassrooms(campus: selectedCampus, week: selectedWeek, dayOfWeek: selectedDayOfWeek, section: selectedSection).sorted()
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = "请先登录教务系统后再查询数据"
                    self.isShowingWarning = true
                }
            }
        }
    }
}
