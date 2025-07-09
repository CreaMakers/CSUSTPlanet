//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct FunctionItem<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.accent)
                }

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
        }
    }
}

struct FeaturesView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        if let _ = userManager.user {
            ScrollView {
                VStack(spacing: 20) {
                    Text("常用功能")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 15) {
                        FunctionItem(icon: "doc.text.magnifyingglass", title: "成绩查询", destination: GradeQueryView())
                        FunctionItem(icon: "calendar", title: "课表", destination: CourseScheduleView())
                        FunctionItem(icon: "map", title: "校园地图", destination: Text("校园地图功能待开发"))
                        FunctionItem(icon: "character.book.closed", title: "四六级", destination: Text("四六级功能待开发"))
                    }

                    HStack(spacing: 15) {
                        FunctionItem(icon: "pencil.and.outline", title: "考试安排", destination: ExamScheduleView())
                        FunctionItem(icon: "calendar.badge.clock", title: "校历", destination: Text("校历功能待开发"))
                        FunctionItem(icon: "bolt.fill", title: "电费查询", destination: ElectricityQueryView())
                        FunctionItem(icon: "mic.fill", title: "普通话", destination: Text("普通话功能待开发"))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .navigationTitle("功能")
        } else {
            NotLoginView()
        }
    }
}

#Preview {
    NavigationStack {
        FeaturesView()
    }
    .environmentObject(UserManager())
}
