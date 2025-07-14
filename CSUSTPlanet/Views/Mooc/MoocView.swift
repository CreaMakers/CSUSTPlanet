//
//  MoocView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import SwiftUI

struct MoocView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    CoursesView(authManager: authManager)
                } label: {
                    Label("课程列表", systemImage: "book.fill")
                }
            }
        }
        .navigationTitle("网络课程中心")
    }
}

#Preview {
    MoocView()
        .environmentObject(AuthManager())
}
