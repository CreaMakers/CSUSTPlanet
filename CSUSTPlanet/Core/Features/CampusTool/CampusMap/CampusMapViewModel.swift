//
//  CampusMapViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/01/09.
//

import CSUSTKit
import MapKit
import SwiftUI

enum BuildingCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case teachingBuilding = "teaching-building"
    case library = "library"
    case dormitory = "dormitory"
    case canteen = "canteen"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "全部"
        case .teachingBuilding: return "教学楼"
        case .library: return "图书馆"
        case .dormitory: return "宿舍"
        case .canteen: return "食堂"
        case .other: return "其他"
        }
    }
}

// GeoJSON Data Models
struct GeoJSON: Decodable {
    let type: String
    let features: [Feature]
}

struct Feature: Decodable, Identifiable {
    let type: String
    let properties: FeatureProperties
    let geometry: FeatureGeometry

    var id: String { properties.name }

    static func == (lhs: Feature, rhs: Feature) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Feature: Equatable, Hashable {}

struct FeatureProperties: Decodable {
    let name: String
    let category: String
}

struct FeatureGeometry: Decodable {
    let type: String
    let coordinates: [[[Double]]]
}

@MainActor
final class CampusMapViewModel: ObservableObject {
    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @Published var isOnlineMapShown: Bool = false
    @Published var allBuildings: [Feature] = []
    @Published var selectedCategory: BuildingCategory = .all
    @Published var selectedBuilding: Feature? {
        didSet {
            if let building = selectedBuilding {
                let center = getCenter(for: building)
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)))
                }
            }
        }
    }
    @Published var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(center: CampusMapViewModel.defaultLocation, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))

    static let defaultLocation = CLLocationCoordinate2D(latitude: 28.160, longitude: 112.972)  // Adjusted slightly to center clearer

    var filteredBuildings: [Feature] {
        if selectedCategory == .all {
            return allBuildings
        }
        return allBuildings.filter { $0.properties.category == selectedCategory.rawValue }
    }

    // Helper to cache polygon coordinates
    private var buildingPolygons: [String: [CLLocationCoordinate2D]] = [:]

    init() {
        loadBuildings()
    }

    func loadBuildings() {
        guard let url = Bundle.main.url(forResource: "map", withExtension: "geojson") ?? Bundle.main.url(forResource: "map", withExtension: "json") else {
            print("Failed to find map.geojson")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
            self.allBuildings = geoJSON.features
        } catch {
            print("Failed to decode buildings: \(error)")
        }
    }

    func getPolygonCoordinates(for building: Feature) -> [CLLocationCoordinate2D] {
        if let cached = buildingPolygons[building.id] {
            return cached
        }

        guard let firstRing = building.geometry.coordinates.first else { return [] }
        let coords = firstRing.map { coord in
            CoordinateConverter.wgs84ToGcj02(lat: coord[1], lon: coord[0])
        }
        buildingPolygons[building.id] = coords
        return coords
    }

    func getCenter(for building: Feature) -> CLLocationCoordinate2D {
        let coords = getPolygonCoordinates(for: building)
        guard !coords.isEmpty else { return .init() }
        let totalLat = coords.reduce(0) { $0 + $1.latitude }
        let totalLon = coords.reduce(0) { $0 + $1.longitude }
        return CLLocationCoordinate2D(latitude: totalLat / Double(coords.count), longitude: totalLon / Double(coords.count))
    }

    func selectBuilding(_ building: Feature) {
        if selectedBuilding == building {
            selectedBuilding = nil
        } else {
            selectedBuilding = building
        }
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
