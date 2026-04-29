//
//  LocationSearchCompleter.swift
//  Iroha
//

import SwiftUI
import MapKit
import Combine

@MainActor
final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0),
            span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
        )
    }

    func search(_ query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        searchCompleter.queryFragment = query
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {}
}
