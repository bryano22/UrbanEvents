import Foundation
import CoreLocation
import SwiftUI

// Conformiamo a Identifiable (per le Liste/Mappe), Codable (per il JSON) e Hashable
struct Event: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let category: String      // valore "grezzo" (es. "Arte"): viene tradotto solo in visualizzazione
    let address: String
    let date: Date            // Data reale: viene formattata nella lingua scelta dall'utente
    let price: Double
    let isFree: Bool
    let imageURL: String
    let latitude: Double
    let longitude: Double

    // Proprietà calcolata (Computed Property) utile per MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Categoria tipizzata (per icona e traduzione)
    var eventCategory: EventCategory {
        EventCategory(rawValue: category) ?? .other
    }

    /// Formato usato nel JSON (es. "15 Nov 2026 - 18:00").
    /// Locale POSIX: il parsing non dipende dalla lingua del dispositivo.
    static let storageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy - HH:mm"
        return formatter
    }()
}

// Codable in un'extension: così Swift genera comunque l'init "memberwise"
extension Event: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, address, date, price, isFree, imageURL, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        category = try c.decode(String.self, forKey: .category)
        address = try c.decode(String.self, forKey: .address)
        price = try c.decode(Double.self, forKey: .price)
        isFree = try c.decode(Bool.self, forKey: .isFree)
        imageURL = try c.decode(String.self, forKey: .imageURL)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)

        let dateString = try c.decode(String.self, forKey: .date)
        guard let parsed = Event.storageDateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: c,
                debugDescription: "Formato data non valido: \(dateString)")
        }
        date = parsed
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(category, forKey: .category)
        try c.encode(address, forKey: .address)
        try c.encode(Event.storageDateFormatter.string(from: date), forKey: .date)
        try c.encode(price, forKey: .price)
        try c.encode(isFree, forKey: .isFree)
        try c.encode(imageURL, forKey: .imageURL)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
    }
}

// MARK: - Categoria

enum EventCategory: String, CaseIterable, Identifiable {
    case art = "Arte"
    case music = "Musica"
    case theatre = "Teatro"
    case cinema = "Cinema"
    case food = "Cibo & Vino"
    case sport = "Sport"
    case other = "Altro"

    var id: String { rawValue }

    /// Chiave del file Localizable (la chiave è il testo italiano)
    var titleKey: LocalizedStringKey { LocalizedStringKey(rawValue) }

    var icon: String {
        switch self {
        case .art: return "paintpalette"
        case .music: return "music.note"
        case .theatre: return "theatermasks"
        case .cinema: return "film"
        case .food: return "fork.knife"
        case .sport: return "figure.run"
        case .other: return "sparkles"
        }
    }
}

// MARK: - Acquisto

/// Un acquisto/prenotazione. Salviamo una "fotografia" dei dati dell'evento,
/// così il biglietto resta visibile anche se l'evento non è più in elenco.
struct Purchase: Identifiable, Codable, Hashable {
    let id: UUID
    let eventID: UUID
    let eventTitle: String
    let eventAddress: String
    let eventDate: Date
    let eventImageURL: String
    let quantity: Int
    let unitPrice: Double
    let purchaseDate: Date

    var total: Double { unitPrice * Double(quantity) }
    var isFree: Bool { unitPrice == 0 }
}
