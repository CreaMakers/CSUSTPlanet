//
//  FeedbackView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//
import SwiftUI

struct FeedbackView: View {
    // 飞书问卷链接
    private let surveyURL = URL(string: "https://my.feishu.cn/share/base/form/shrcnmYT0Hn0MEWoV11cnfi7zHg")!
    // QQ 群链接
    private let qqGroupURL = URL(string: "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=125010161&key=&card_type=group&source=external")!
    // 邮箱链接
    private let emailURL = URL(string: "mailto:developer@zhelearn.com")!

    @State private var isShowingSurveySheet = false
    @State private var webViewController = WebViewController()
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Button(action: {
                    #if os(macOS)
                    openURL(surveyURL)
                    #else
                    isShowingSurveySheet = true
                    #endif
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("填写意见调研问卷")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("快速反馈您遇到的问题或建议")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            } header: {
                Text("推荐方式")
            } footer: {
                Text("您的反馈对我们非常重要！无论是功能建议、BUG 报告，还是使用体验上的优化，我们都会认真阅读并持续改进。🚀")
            }

            Section {
                Link(destination: emailURL) {
                    Label {
                        Text(verbatim: "邮箱反馈 (developer@zhelearn.com)")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                    }
                }

                Link(destination: qqGroupURL) {
                    Label {
                        Text("QQ 交流群 (125010161)")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                    }
                }
            } header: {
                Text("其他联系方式")
            }

            Section {
                Text("感谢您对 **长理星球** 的支持！")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .sheet(isPresented: $isShowingSurveySheet) {
            NavigationStack {
                WebView(url: surveyURL, controller: webViewController)
                .navigationTitle("填写意见调研问卷")
                .inlineToolbarTitle()
                .toolbar {
                    WebViewControlsToolbar(controller: webViewController)

                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") {
                            isShowingSurveySheet = false
                        }
                    }
                }
            }
        }
        #endif
        .navigationTitle("意见反馈")
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}
