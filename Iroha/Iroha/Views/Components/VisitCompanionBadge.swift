//
//  VisitCompanionBadge.swift
//  Iroha
//

import SwiftUI

struct VisitCompanionBadge: View {
    let companions: [String]

    var body: some View {
        if !companions.isEmpty {
            HStack(spacing: 3) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 9))
                if companions.count == 1 {
                    Text(companions[0].prefix(4))
                        .font(.system(size: 10))
                } else {
                    Text(verbatim: "\(companions.count)人")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.irohaFuji)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.irohaFujiLt.opacity(0.3))
            .clipShape(Capsule())
        }
    }
}
