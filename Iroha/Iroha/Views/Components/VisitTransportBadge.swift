//
//  VisitTransportBadge.swift
//  Iroha
//

import SwiftUI

struct VisitTransportBadge: View {
    let transports: [VisitTransport]

    var body: some View {
        if !transports.isEmpty {
            HStack(spacing: 3) {
                ForEach(transports, id: \.rawValue) { transport in
                    Image(systemName: transport.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(transport.foregroundColor)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.irohaWashi2)
            .clipShape(Capsule())
        }
    }
}
