//
//  CampusMapViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/01/09.
//

import CSUSTKit
import MapKit
import SwiftUI

@MainActor
final class CampusMapViewModel: ObservableObject {
    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @Published var isOnlineMapShown: Bool = false
    @Published var buildings: [Building] = []

    static let defaultLocation = CLLocationCoordinate2D(latitude: 28.158, longitude: 112.972)

    var mapImageName: String {
        switch selectedCampus {
        case .yuntang: return "YuntangMap"
        case .jinpenling: return "JinpenlingMap"
        }
    }

    init() {
        loadBuildings()
    }

    func loadBuildings() {
        guard let url = Bundle.main.url(forResource: "map", withExtension: "json") else {
            print("Failed to find map.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.buildings = try JSONDecoder().decode([Building].self, from: data)
        } catch {
            print("Failed to decode buildings: \(error)")
        }
    }
}

struct Building: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let coordinates: [[[Double]]]

    var polygonCoordinates: [CLLocationCoordinate2D] {
        guard let firstRing = coordinates.first else { return [] }
        return firstRing.map { coord in
            CoordinateConverter.wgs84ToGcj02(lat: coord[1], lon: coord[0])
        }
    }

    var center: CLLocationCoordinate2D {
        let coords = polygonCoordinates
        guard !coords.isEmpty else { return .init() }
        let totalLat = coords.reduce(0) { $0 + $1.latitude }
        let totalLon = coords.reduce(0) { $0 + $1.longitude }
        return CLLocationCoordinate2D(latitude: totalLat / Double(coords.count), longitude: totalLon / Double(coords.count))
    }
}

struct CoordinateConverter {
    static let a = 6378245.0
    static let ee = 0.00669342162296594323

    static func wgs84ToGcj02(lat: Double, lon: Double) -> CLLocationCoordinate2D {
        if outOfChina(lat: lat, lon: lon) {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
        var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)
        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
        return CLLocationCoordinate2D(latitude: lat + dLat, longitude: lon + dLon)
    }

    static func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    static func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }

    static func outOfChina(lat: Double, lon: Double) -> Bool {
        if lon < 72.004 || lon > 137.8347 { return true }
        if lat < 0.8293 || lat > 55.8271 { return true }
        return false
    }
}
