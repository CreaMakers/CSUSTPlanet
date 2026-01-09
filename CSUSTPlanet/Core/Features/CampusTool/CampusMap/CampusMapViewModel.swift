//
//  CampusMapViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/9.
//

import CSUSTKit
import MapKit
import SwiftUI

// GeoJSON Data Models
struct GeoJSON: Decodable {
    let type: String
    let features: [Feature]
}

struct Feature: Decodable, Identifiable, Equatable, Hashable {
    let type: String
    let properties: FeatureProperties
    let geometry: FeatureGeometry

    var id: String { properties.name + properties.campus }
}

struct FeatureProperties: Decodable, Hashable {
    let name: String
    let category: String
    let campus: String
}

struct FeatureGeometry: Decodable, Hashable {
    let type: String
    let coordinates: [[[Double]]]
}

@MainActor
final class CampusMapViewModel: ObservableObject {
    @Published var selectedCampus: CampusCardHelper.Campus = .jinpenling {
        didSet {
            selectedCategory = nil
            selectedBuilding = nil
            centerMapOnCampus()
        }
    }
    @Published var isOnlineMapShown: Bool = false
    @Published var allBuildings: [Feature] = []
    @Published var selectedCategory: String? = nil
    @Published var selectedBuilding: Feature? {
        didSet {
            if let building = selectedBuilding {
                let center = getCenter(for: building)
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.013)))
                }
            }
        }
    }
    @Published var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(center: CampusMapViewModel.defaultLocation, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))

    static let defaultLocation = CLLocationCoordinate2D(latitude: 28.160, longitude: 112.972)

    var availableCategories: [String?] {
        let buildings = allBuildings.filter { $0.properties.campus == selectedCampus.rawValue }
        let existingCategories = Set(buildings.map { $0.properties.category })
        var categories: [String?] = Array(existingCategories).sorted().map { Optional($0) }
        categories.insert(nil, at: 0)
        return categories
    }

    var filteredBuildings: [Feature] {
        let campusBuildings = allBuildings.filter { $0.properties.campus == selectedCampus.rawValue }

        guard let category = selectedCategory else {
            return campusBuildings
        }
        return campusBuildings.filter { $0.properties.category == category }
    }

    private var buildingPolygons: [String: [CLLocationCoordinate2D]] = [:]

    init() {
        loadBuildings()
    }

    func loadBuildings() {
        guard let url = Bundle.main.url(forResource: "map", withExtension: "geojson") else {
            print("Failed to find map.geojson")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
            self.allBuildings = geoJSON.features.sorted {
                $0.properties.name.localizedStandardCompare($1.properties.name) == .orderedAscending
            }
            centerMapOnCampus()
        } catch {
            print("Failed to decode buildings: \(error)")
        }
    }

    func centerMapOnCampus() {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(center: selectedCampus.center, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)))
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

    func color(for category: String) -> Color {
        switch category {
        case "教学楼": return .orange
        case "图书馆": return .blue
        case "体育": return .cyan
        case "食堂": return .red
        case "宿舍", "东苑宿舍", "南苑宿舍", "西苑宿舍": return .green
        case "行政办公": return .purple
        case "生活休闲": return .pink
        default: return .gray
        }
    }

    func icon(for category: String) -> String {
        switch category {
        case "教学楼": return "building.columns.fill"
        case "图书馆": return "books.vertical.fill"
        case "体育": return "sportscourt.fill"
        case "食堂": return "fork.knife"
        case "宿舍", "东苑宿舍", "南苑宿舍", "西苑宿舍": return "bed.double.fill"
        case "行政办公": return "briefcase.fill"
        case "生活休闲": return "cup.and.saucer.fill"
        default: return "building.2.fill"
        }
    }
}

extension CampusCardHelper.Campus {
    var center: CLLocationCoordinate2D {
        switch self {
        case .jinpenling:
            return CLLocationCoordinate2D(latitude: 28.154679492037516, longitude: 112.97786900346351)
        case .yuntang:
            return CLLocationCoordinate2D(latitude: 28.06667705205599, longitude: 113.00821135314567)
        }
    }
}
