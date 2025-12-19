//
//  InfoRow.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/29.
//

import Inject
import SwiftUI

struct InfoRow: View {
    @ObserveInjection var inject

    init(icon: (String, Color)? = nil, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
    }
    let icon: (String, Color)?
    let label: String?
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon.0)
                    .frame(width: 20)
                    .foregroundStyle(icon.1)
                VStack(alignment: .leading, spacing: 2) {
                    if let label = label {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
            } else {
                if let label = label {
                    Text(label)
                    Spacer()
                }
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = value
            }) {
                Label("复制值", systemImage: "doc.on.doc")
            }
            if let label = label {
                Button(action: {
                    UIPasteboard.general.string = "\(label): \(value)"
                }) {
                    Label("复制全部", systemImage: "doc.on.doc.fill")
                }
            }
        }
        .enableInjection()
    }
}
