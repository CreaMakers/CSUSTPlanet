//
//  EvalView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/6/17.
//

import CSUSTKit
import SwiftUI
import WebKit

struct EvalView: View {
    @State private var webViewController = WebViewController()
    @State private var autofillController = EvalAutofillController()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            EvalBrowserView(
                controller: webViewController,
                autofillController: autofillController
            )

            if autofillController.isAvailable {
                Button {
                    autofillController.presentCustomScoreSheet()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("辅助填写")
                    }
                }
                .controlSize(.large)
                .apply { view in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        view.buttonStyle(.glassProminent)
                    } else {
                        view.buttonStyle(.borderedProminent)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.default, value: autofillController.isAvailable)
        .sheet(isPresented: $autofillController.isCustomScoreSheetPresented) {
            #if os(iOS)
            EvalCustomScoreSheet(controller: autofillController)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            #else
            EvalCustomScoreSheet(controller: autofillController)
                .frame(width: 420, height: 280)
            #endif
        }
        .successToast($autofillController.successToast)
        .inlineToolbarTitle()
        .navigationTitle("评教系统")
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}
