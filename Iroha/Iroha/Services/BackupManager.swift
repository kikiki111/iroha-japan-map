//
//  BackupManager.swift
//  Iroha
//

import Foundation
import SwiftData

struct BackupPayload: Codable {
    let version: Int
    let exportedAt: Date
    let prefectures: [PrefectureBackup]
}

struct PrefectureBackup: Codable {
    let code: Int
    let visits: [VisitBackup]
}

struct VisitBackup: Codable {
    let startDate: Date
    let endDate: Date?
    let note: String
    let tag: String?
    let mood: String?
    let transports: [String]?
    let tripName: String?
    let companions: [String]?
    let location: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
}

enum BackupManager {

    static func export(prefectures: [Prefecture]) throws -> URL {
        let payload = BackupPayload(
            version: 3,
            exportedAt: Date(),
            prefectures: prefectures.compactMap { pref in
                guard pref.isVisited else { return nil }
                return PrefectureBackup(
                    code: pref.id,
                    visits: pref.visits.map { visit in
                        VisitBackup(
                            startDate: visit.startDate,
                            endDate: visit.endDate,
                            note: visit.note,
                            tag: visit.effectiveTag == .none ? nil : visit.effectiveTag.rawValue,
                            mood: visit.effectiveMood == .none ? nil : visit.effectiveMood.rawValue,
                            transports: visit.transports.isEmpty ? nil : visit.transports,
                            tripName: visit.tripName.isEmpty ? nil : visit.tripName,
                            companions: visit.companions.isEmpty ? nil : visit.companions,
                            location: visit.location.isEmpty ? nil : visit.location,
                            locationLatitude: visit.locationLatitude,
                            locationLongitude: visit.locationLongitude
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "iroha_backup_\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }

    static func restore(from url: URL, prefectures: [Prefecture], context: ModelContext) throws -> Int {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        guard payload.version <= 3 else {
            throw BackupError.unsupportedVersion
        }

        let photoFilenamesToDelete = Set(prefectures.flatMap { pref in
            pref.visits.flatMap(\.allPhotoFilenames)
        })

        for pref in prefectures {
            for visit in pref.visits {
                context.delete(visit)
            }
        }

        var importedCount = 0

        for prefBackup in payload.prefectures {
            guard let pref = prefectures.first(where: { $0.id == prefBackup.code }) else { continue }

            for visitBackup in prefBackup.visits {
                let visit = Visit(
                    prefectureName: pref.name,
                    startDate: visitBackup.startDate,
                    endDate: visitBackup.endDate,
                    note: visitBackup.note,
                    tag: visitBackup.tag.flatMap { VisitTag(rawValue: $0) } ?? .none
                )
                visit.mood = visitBackup.mood.flatMap { VisitMood(rawValue: $0) }
                visit.transports = visitBackup.transports ?? []
                visit.tripName = visitBackup.tripName ?? ""
                visit.companions = visitBackup.companions ?? []
                visit.location = visitBackup.location ?? ""
                visit.locationLatitude = visitBackup.locationLatitude
                visit.locationLongitude = visitBackup.locationLongitude
                visit.prefecture = pref
                context.insert(visit)
                importedCount += 1
            }
        }

        try context.save()
        for filename in photoFilenamesToDelete {
            PhotoStorageManager.delete(filename: filename)
        }

        return importedCount
    }

    enum BackupError: LocalizedError {
        case unsupportedVersion

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion: return "サポートされていないバックアップ形式です"
            }
        }
    }
}
