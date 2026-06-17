//
//  ConflictCourseCardView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/1.
//

import SwiftUI

struct ConflictCourseCardView: View {
    let courses: [CourseDisplayInfo]
    let isPad: Bool
    let onSelect: (CourseDisplayInfo) -> Void

    @State private var isShowingPopover = false

    var body: some View {
        #if os(macOS)
        cardVisual
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingPopover.toggle()
            }
            .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
                macOSPopoverContent
            }
        #else
        Menu {
            Section("存在课程冲突，请选择") {
                ForEach(courses) { info in
                    Button {
                        onSelect(info)
                    } label: {
                        let room = info.session.classroom ?? "未知"
                        Text("\(info.course.courseName) (@\(room))") + Text("\n第\(info.session.startSection)-\(info.session.endSection)节").font(.caption)
                    }
                }
            }
        } label: {
            cardVisual
        }
        #endif
    }

    private var cardVisual: some View {
        ZStack {
            StripedBackground(stripeColor: Color.white.opacity(0.25), backgroundColor: Color.red)

            VStack(spacing: isPad ? 6 : 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: isPad ? 18 : 14))
                    .foregroundColor(.white)
                Text("课程冲突")
                    .font(.system(size: isPad ? 14 : 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .cornerRadius(isPad ? 10 : 6)
        .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
    }

    #if os(macOS)
    private var macOSPopoverContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("存在课程冲突，请选择")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(courses) { info in
                        Button {
                            isShowingPopover = false
                            onSelect(info)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(info.course.courseName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)

                                    if let room = info.session.classroom {
                                        Text("@\(room)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }

                                    Text("第\(info.session.startSection)-\(info.session.endSection)节")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if info.id != courses.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 240)
        .padding(.bottom, 8)
    }
    #endif
}

struct StripedBackground: View {
    var stripeColor: Color
    var backgroundColor: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let diagonal = sqrt(width * width + height * height)
            let stripeWidth: CGFloat = 6
            let spacing = stripeWidth * 2

            Path { path in
                for i in stride(from: -diagonal, to: diagonal, by: spacing) {
                    path.move(to: CGPoint(x: i, y: -diagonal))
                    path.addLine(to: CGPoint(x: i + diagonal * 2, y: diagonal))
                }
            }
            .stroke(stripeColor, lineWidth: stripeWidth)
            .background(backgroundColor)
        }
        .clipped()
    }
}
