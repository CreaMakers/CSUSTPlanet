//
//  OnboardingView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingView: View {
    let onSkip: () -> Void
    let presentingColorScheme: ColorScheme

    @Bindable private var globalManager = GlobalManager.shared
    @State private var currentPage = 0
    @State private var dormViewModel = DormListViewModel()

    private let totalPages = 6

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    currentPageView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.18))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.snappy(duration: 0.22), value: currentPage)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task { await dormViewModel.loadInitial() }
            .navigationTitle(currentNavigationTitle)
            .navigationSubtitleCompat("步骤 \(currentPage + 1) / \(totalPages)")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过", action: onSkip)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(currentPage == totalPages - 1 ? "开始使用" : "下一步", action: handlePrimaryAction)
                }
            }
        }
        #if os(iOS)
        .preferredColorScheme(sheetPreferredColorScheme)
        #endif
    }

    private func handlePrimaryAction() {
        if currentPage == totalPages - 1 {
            onSkip()
            return
        }

        withAnimation(.snappy(duration: 0.28)) {
            currentPage += 1
        }
    }

    #if os(iOS)
    private var sheetPreferredColorScheme: ColorScheme? {
        switch globalManager.appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return presentingColorScheme
        }
    }
    #endif

    @ViewBuilder
    private var currentPageView: some View {
        switch currentPage {
        case 0:
            OnboardingWelcomePage()
                .transition(pageTransition)
        case 1:
            OnboardingLoginPage()
                .transition(pageTransition)
        case 2:
            OnboardingDormSetupPage(viewModel: dormViewModel)
                .transition(pageTransition)
        case 3:
            OnboardingWidgetPage()
                .transition(pageTransition)
        case 4:
            OnboardingSettingsPage()
                .transition(pageTransition)
        default:
            OnboardingCompletionPage()
                .transition(pageTransition)
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var currentNavigationTitle: String {
        switch currentPage {
        case 0: return "长理星球"
        case 1: return "账号登录"
        case 2: return "宿舍配置"
        case 3: return "桌面小组件"
        case 4: return "偏好设置"
        default: return "设置完成"
        }
    }
}
