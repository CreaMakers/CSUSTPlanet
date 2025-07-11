//
//  SchoolCalendarView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct SchoolCalendarView: View {
    var body: some View {
        WebView(url: URL(string: "https://www.csust.edu.cn/jwc/jxyx/jxxl.htm")!)
    }
}

#Preview {
    SchoolCalendarView()
}
