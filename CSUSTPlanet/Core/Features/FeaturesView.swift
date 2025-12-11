//
//  FeaturesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Inject
import SwiftUI

struct FeaturesView: View {
    @ObserveInjection var inject

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalVars: GlobalVars
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPhysicsExperimentLoginPresented: Bool = false
    @StateObject var physicsExperimentManager = PhysicsExperimentManager.shared

    // MARK: - Layout Constants
    private let spacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: spacing) {
                    sectionHeader(title: "教务系统", icon: "graduationcap.fill", color: .blue) {
                        Group {
                            if authManager.isSSOLoggingIn {
                                StatusBadge(text: "SSO登录中", state: .loading)
                            } else if !authManager.isLoggedIn {
                                ActionBadge(text: "点击登录", icon: "person.crop.circle.badge.exclamationmark") {
                                    globalVars.selectedTab = .profile
                                }
                            } else if authManager.isEducationLoggingIn {
                                StatusBadge(text: "教务登录中", state: .loading)
                            } else {
                                ActionBadge(text: "刷新登录", icon: "arrow.clockwise") {
                                    authManager.loginToEducation()
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: spacing), GridItem(.flexible(), spacing: spacing)], spacing: spacing) {
                        HeroCard(destination: CourseScheduleView(), title: "我的课表", subtitle: "每周课程", icon: "calendar", gradient: .purple)
                        HeroCard(destination: GradeQueryView(), title: "成绩查询", subtitle: "GPA / 成绩详细", icon: "doc.text.magnifyingglass", gradient: .blue)
                        HeroCard(destination: ExamScheduleView(), title: "考试安排", subtitle: "考场 / 时间", icon: "pencil.and.outline", gradient: .orange)
                        HeroCard(destination: GradeAnalysisView(), title: "成绩分析", subtitle: "可视化图表", icon: "chart.bar.xaxis", gradient: .green)
                    }
                }
                .padding(.horizontal, horizontalPadding)

                VStack(spacing: spacing) {
                    sectionHeader(title: "网络课程中心", icon: "book.closed.fill", color: .indigo) {
                        Group {
                            if authManager.isMoocLoggingIn {
                                StatusBadge(text: "课程中心登录中", state: .loading)
                            } else if authManager.isLoggedIn && !authManager.isSSOLoggingIn {
                                ActionBadge(text: "刷新登录", icon: "arrow.clockwise") {
                                    authManager.loginToMooc()
                                }
                            }
                        }
                    }

                    HStack(spacing: spacing) {
                        MediumCard(destination: CoursesView(), title: "所有课程", icon: "books.vertical.fill", color: .indigo)
                        MediumCard(destination: UrgentCoursesView(), title: "待办作业", icon: "list.bullet.clipboard", color: .red)
                    }
                }
                .padding(.horizontal, horizontalPadding)

                VStack(alignment: .leading, spacing: 12) {
                    Text("校园工具")
                        .font(.title3.bold())
                        .padding(.horizontal, horizontalPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Spacer().frame(width: horizontalPadding - 12)

                            ServiceSquare(destination: ElectricityQueryView(), title: "电量查询", icon: "bolt.fill", color: .yellow)
                            ServiceSquare(destination: ElectricityRechargeView(), title: "电费充值", icon: "creditcard.fill", color: .cyan)
                            ServiceSquare(destination: CampusMapView(), title: "校园地图", icon: "map.fill", color: .mint)
                            ServiceSquare(destination: SchoolCalendarListView(), title: "校历", icon: "calendar.badge.clock", color: .pink)
                            ServiceSquare(destination: WebVPNConverterView(), title: "WebVPN", icon: "lock.shield", color: .gray)

                            Spacer().frame(width: horizontalPadding - 12)
                        }
                    }
                }

                VStack(spacing: spacing) {
                    sectionHeader(title: "大学物理实验", icon: "atom", color: .purple) {
                        Button {
                            isPhysicsExperimentLoginPresented = true
                        } label: {
                            Text("登录")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    VStack(spacing: 0) {
                        ToolRow(
                            destination: PhysicsExperimentScheduleView().environmentObject(physicsExperimentManager),
                            title: "物理实验安排", icon: "calendar", color: .purple)

                        Divider().padding(.leading, 56)

                        ToolRow(
                            destination: PhysicsExperimentGradeView().environmentObject(physicsExperimentManager),
                            title: "物理实验成绩", icon: "doc.text", color: .purple
                        )
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, horizontalPadding)
                .sheet(isPresented: $isPhysicsExperimentLoginPresented) {
                    PhysicsExperimentLoginView(isPresented: $isPhysicsExperimentLoginPresented)
                        .environmentObject(physicsExperimentManager)
                }

                VStack(spacing: spacing) {
                    sectionHeader(title: "考试查询", icon: "magnifyingglass.circle.fill", color: .indigo)

                    VStack(spacing: 0) {
                        ToolRow(destination: CETView(), title: "四六级查询", icon: "character.book.closed", color: .brown)

                        Divider().padding(.leading, 56)

                        ToolRow(destination: MandarinView(), title: "普通话查询", icon: "mic.circle.fill", color: .teal)
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, horizontalPadding)

                Color.clear.frame(height: 20)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .enableInjection()
    }

    // MARK: - Subviews & Components

    @ViewBuilder
    private func sectionHeader<Content: View>(title: String, icon: String, color: Color, @ViewBuilder actions: () -> Content = { EmptyView() }) -> some View {
        HStack(alignment: .center) {
            Label {
                Text(title)
                    .font(.title3.bold())
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            Spacer()

            actions()
        }
    }
}

// MARK: - Custom Card Components

internal struct HeroCard<Destination: View>: View {
    let destination: Destination
    let title: String
    let subtitle: String
    let icon: String
    let gradient: Color

    var body: some View {
        NavigationLink(destination: destination) {
            ZStack(alignment: .bottomLeading) {
                // Background
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gradient.opacity(0.85), gradient],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: gradient.opacity(0.3), radius: 8, x: 0, y: 4)

                // Decor Icon (Large, transparent)
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: 20, y: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .clipped()

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)

                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(16)
            }
            .frame(height: 120)
        }
    }
}

internal struct MediumCard<Destination: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .cornerRadius(10)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}

internal struct ServiceSquare<Destination: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color.opacity(0.15)))

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 85, height: 95)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

internal struct ToolRow<Destination: View, Accessory: View>: View {
    let destination: Destination
    let title: String
    let icon: String
    let color: Color
    var accessory: (() -> Accessory)? = nil

    init(destination: Destination, title: String, icon: String, color: Color, @ViewBuilder accessory: @escaping () -> Accessory) {
        self.destination = destination
        self.title = title
        self.icon = icon
        self.color = color
        self.accessory = accessory
    }

    // Overload for no accessory
    init(destination: Destination, title: String, icon: String, color: Color) where Accessory == EmptyView {
        self.destination = destination
        self.title = title
        self.icon = icon
        self.color = color
        self.accessory = nil
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .cornerRadius(7)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                if let accessory = accessory {
                    accessory()
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Status Indicators

struct ActionBadge: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.1)))
            .foregroundColor(.blue)
        }
    }
}

struct StatusBadge: View {
    enum State { case loading, success, error }
    let text: String
    let state: State

    var body: some View {
        HStack(spacing: 6) {
            if state == .loading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 10, height: 10)
            }
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.secondary.opacity(0.1)))
        .foregroundColor(.secondary)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        FeaturesView()
            .environmentObject(AuthManager.shared)
            .environmentObject(GlobalVars.shared)
    }
}
