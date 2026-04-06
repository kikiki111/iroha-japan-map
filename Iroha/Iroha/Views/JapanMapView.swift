//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import MapKit

struct JapanMapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        Map(coordinateRegion: $viewModel.region,
            annotationItems: viewModel.focusedPrefecture.map { [$0] } ?? []) { prefecture in
            MapAnnotation(coordinate: prefecture.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text(prefecture.name)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    JapanMapView(viewModel: MapViewModel())
}
