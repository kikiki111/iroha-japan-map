//
//  LocationSearchCompleter.swift
//  Iroha
//

import SwiftUI
import MapKit
import Combine

struct PlaceSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
}

@MainActor
final class LocationSearchCompleter: ObservableObject {
    @Published var results: [PlaceSuggestion] = []

    private var searchTask: Task<Void, Never>?
    private let debounceNanoseconds: UInt64 = 300_000_000
    private let maxResults = 10
    private let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )

    func search(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        searchTask = Task { [weak self, debounceNanoseconds, region, maxResults] in
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            if Task.isCancelled { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.region = region
            var resultTypes: MKLocalSearch.ResultType = [.address, .pointOfInterest]
            if #available(iOS 18.0, *) {
                resultTypes.insert(.physicalFeature)
            }
            request.resultTypes = resultTypes

            let search = MKLocalSearch(request: request)
            guard let response = try? await search.start() else {
                if Task.isCancelled { return }
                await MainActor.run { self?.results = [] }
                return
            }
            if Task.isCancelled { return }

            let suggestions: [PlaceSuggestion] = response.mapItems.prefix(maxResults).map { item in
                PlaceSuggestion(
                    title: item.name ?? trimmed,
                    subtitle: Self.formatSubtitle(item.placemark),
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
            await MainActor.run { self?.results = suggestions }
        }
    }

    private static func formatSubtitle(_ placemark: MKPlacemark) -> String {
        let parts = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.thoroughfare
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }
}
