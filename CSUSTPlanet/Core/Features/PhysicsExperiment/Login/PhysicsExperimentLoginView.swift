//
//  PhysicsExperimentLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import SwiftUI

struct PhysicsExperimentLoginView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Text("Hello, World!")
                .navigationTitle("登录大物实验")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { isPresented = false }) {
                            Text("关闭")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {}) {
                            Text("登录")
                        }
                    }
                }
        }
    }
}

#Preview {
    PhysicsExperimentLoginView(isPresented: .constant(true))
}
