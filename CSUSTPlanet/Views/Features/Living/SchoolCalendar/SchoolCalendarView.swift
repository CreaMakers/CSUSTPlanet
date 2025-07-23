//
//  SchoolCalendarView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct SchoolCalendarView: View {
    let semester: String

    var url: URL {
        URL(string: "https://api.csustplanet.zhelearn.com/static/school_calendar/index.html?config=\(semester)")!
    }

    var body: some View {
        WebView(url: url)
            .navigationTitle("\(semester) 学期校历")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SchoolCalendarView(semester: "2025-2026-1")
}
