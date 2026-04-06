//
//  MapViewModel.swift
//  Iroha
//

import Foundation
import MapKit
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    /// The prefecture currently highlighted on the map (nil = none).
    @Published var focusedPrefecture: Prefecture?

    /// The visible map region; starts centered on Japan.
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
    )

    /// Focuses the map on the given prefecture.
    func focus(prefecture: Prefecture) {
        focusedPrefecture = prefecture
        withAnimation {
            region = MKCoordinateRegion(
                center: prefecture.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
            )
        }
    }
}
