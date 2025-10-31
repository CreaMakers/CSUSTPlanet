//
//  SchoolCalendarListViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import Alamofire
import Foundation

struct SchoolCalendar: Codable, Identifiable {
    var id: String { semester }

    let semester: String
    let title: String
    let subtitle: String
}

@MainActor
class SchoolCalendarListViewModel: ObservableObject {
    @Published var schoolCalendars: [SchoolCalendar] = []
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    func loadSchoolCalendars() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                schoolCalendars = try (await AF.request("\(Constants.backendHost)/static/school_calendar/list.json").serializingDecodable([SchoolCalendar].self).value).sorted { $0.semester > $1.semester }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
