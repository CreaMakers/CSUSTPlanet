//
//  CampusMapViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/9.
//

import Alamofire
import CSUSTKit
import CoreLocation
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
    @Published var selectedCampus: CampusCardHelper.Campus? = nil {
        didSet {
            selectedCategory = nil
            selectedBuilding = nil
            centerMapOnCampus()
        }
    }
    @Published var settingsDetent: PresentationDetent = .fraction(0.3)
    @Published var isOnlineMapShown: Bool = false
    @Published var isBuildingsListShown: Bool = true
    @Published var allBuildings: [Feature] = []
    @Published var selectedCategory: String? = nil
    @Published var searchText: String = ""
    @Published var selectedBuilding: Feature? {
        didSet {
            if let building = selectedBuilding {
                let center = getCenter(for: building)
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))
                }
            }
        }
    }
    @Published var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(center: CampusMapViewModel.defaultLocation, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
    @Published var isLoading: Bool = false
    @Published var isShowingError: Bool = false
    @Published var errorMessage: String = ""

    static let defaultLocation = CLLocationCoordinate2D(latitude: 28.160, longitude: 112.972)

    var availableCategories: [String?] {
        let buildings: [Feature]
        if let campus = selectedCampus {
            buildings = allBuildings.filter { $0.properties.campus == campus.rawValue }
        } else {
            buildings = allBuildings
        }
        let categoriesList = buildings.map { $0.properties.category }
        var uniqueCategories: [String] = []
        var seen: Set<String> = []

        for category in categoriesList {
            if !seen.contains(category) {
                seen.insert(category)
                uniqueCategories.append(category)
            }
        }

        var categories: [String?] = uniqueCategories.map { Optional($0) }
        categories.insert(nil, at: 0)
        return categories
    }

    var filteredBuildings: [Feature] {
        let campusBuildings: [Feature]
        if let campus = selectedCampus {
            campusBuildings = allBuildings.filter { $0.properties.campus == campus.rawValue }
        } else {
            campusBuildings = allBuildings
        }

        let categoryFiltered: [Feature]
        if let category = selectedCategory {
            categoryFiltered = campusBuildings.filter { $0.properties.category == category }
        } else {
            categoryFiltered = campusBuildings
        }

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { fuzzyMatches($0.properties.name, searchText) }
        }
    }

    private var buildingPolygons: [String: [CLLocationCoordinate2D]] = [:]
    private let locationManager = CLLocationManager()

    init() {
        loadBuildings()
        requestLocationPermission()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func loadBuildings() {
        let urlString = "\(Constants.backendHost)/static/campus_map/map.json"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        Task {
            isLoading = true
            defer {
                isLoading = false
            }

            do {
                let geoJSON = try (await AF.request(request).serializingDecodable(GeoJSON.self).value)

                self.allBuildings = geoJSON.features
                centerMapOnCampus()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func centerMapOnCampus() {
        withAnimation {
            if let campus = selectedCampus {
                mapPosition = .region(MKCoordinateRegion(center: campus.center, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)))
            } else {
                let center = CLLocationCoordinate2D(latitude: 28.1106, longitude: 112.993)
                mapPosition = .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)))
            }
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

    func openNavigation(for building: Feature) {
        let coordinate = getCenter(for: building)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = building.properties.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
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

    private func fuzzyMatches(_ string: String, _ pattern: String) -> Bool {
        if pattern.isEmpty { return true }
        let target = string.lowercased()
        let query = pattern.lowercased()

        var targetIndex = target.startIndex
        var queryIndex = query.startIndex
        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                queryIndex = query.index(after: queryIndex)
            }
            targetIndex = target.index(after: targetIndex)
        }

        return queryIndex == query.endIndex
    }

    func toggleBuildingsList() {
        isBuildingsListShown.toggle()
        if isBuildingsListShown {
            settingsDetent = .fraction(0.3)
        }
    }

    func showOnlineMap() {
        isBuildingsListShown = false
        isOnlineMapShown = true
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
