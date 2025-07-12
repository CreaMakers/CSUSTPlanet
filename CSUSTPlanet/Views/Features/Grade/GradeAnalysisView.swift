//
//  GradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct GradeAnalysisView: View {
    @StateObject var viewModel: GradeAnalysisViewModel

    init(authManager: AuthManager) {
        self._viewModel = StateObject(wrappedValue: GradeAnalysisViewModel(eduHelper: authManager.eduHelper))
    }

    var body: some View {
        ScrollView {
            Text("成绩分析内容")
        }
        .task {
            viewModel.getCourseGrades()
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationTitle("成绩分析")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.getCourseGrades()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isQuerying)
            }
        }
    }
}

#Preview {
    GradeAnalysisView(authManager: AuthManager())
}
