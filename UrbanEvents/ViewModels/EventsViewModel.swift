import Foundation

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []

    /// Preferiti salvati come insieme di ID (parte VUOTO al primo avvio).
    /// Vengono salvati su UserDefaults, quindi restano anche dopo il riavvio.
    @Published private(set) var favoriteIDs: Set<UUID> = [] {
        didSet { saveFavorites() }
    }

    /// Storico acquisti/prenotazioni (il più recente per primo)
    @Published private(set) var purchases: [Purchase] = [] {
        didSet { savePurchases() }
    }

    /// Evento su cui la mappa deve centrarsi (es. appena creato).
    /// La mappa lo "consuma" rimettendolo a nil dopo averlo mostrato.
    @Published var eventToFocus: Event?

    private let favoritesKey = "favoriteEventIDs"
    private let purchasesKey = "purchases"

    init() {
        loadMockEvents()
        loadFavorites()
        loadPurchases()
    }

    // MARK: - Eventi

    func loadMockEvents() {
        guard let url = Bundle.main.url(forResource: "events_mock", withExtension: "json") else {
            print("File events_mock.json non trovato nel bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            events = try JSONDecoder().decode([Event].self, from: data)
        } catch {
            print("Errore decodifica JSON: \(error)")
        }
    }

    func addEvent(_ event: Event) {
        events.append(event)
        eventToFocus = event
    }

    // MARK: - Preferiti

    /// Eventi preferiti, nello stesso ordine della lista eventi
    var favoriteEvents: [Event] {
        events.filter { favoriteIDs.contains($0.id) }
    }

    func isFavorite(_ event: Event) -> Bool {
        favoriteIDs.contains(event.id)
    }

    // Aggiungi / Rimuovi dai preferiti
    func toggleFavorite(_ event: Event) {
        if favoriteIDs.contains(event.id) {
            favoriteIDs.remove(event.id)
        } else {
            favoriteIDs.insert(event.id)
        }
    }

    /// Usato dallo swipe-to-delete nella lista dei preferiti
    func removeFavorites(at offsets: IndexSet) {
        let current = favoriteEvents
        for index in offsets {
            favoriteIDs.remove(current[index].id)
        }
    }

    // MARK: - Acquisti

    func purchase(_ event: Event, quantity: Int) {
        let purchase = Purchase(
            id: UUID(),
            eventID: event.id,
            eventTitle: event.title,
            eventAddress: event.address,
            eventDate: event.date,
            eventImageURL: event.imageURL,
            quantity: quantity,
            unitPrice: event.isFree ? 0 : event.price,
            purchaseDate: Date()
        )
        purchases.insert(purchase, at: 0)
    }

    /// Biglietti già acquistati per un evento
    func ticketCount(for event: Event) -> Int {
        purchases.filter { $0.eventID == event.id }.reduce(0) { $0 + $1.quantity }
    }

    var totalTickets: Int { purchases.reduce(0) { $0 + $1.quantity } }
    var totalSpent: Double { purchases.reduce(0) { $0 + $1.total } }

    // MARK: - Persistenza (UserDefaults)

    private func saveFavorites() {
        let ids = favoriteIDs.map(\.uuidString)
        UserDefaults.standard.set(ids, forKey: favoritesKey)
    }

    private func loadFavorites() {
        let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favoriteIDs = Set(ids.compactMap(UUID.init(uuidString:)))
    }

    private func savePurchases() {
        if let data = try? JSONEncoder().encode(purchases) {
            UserDefaults.standard.set(data, forKey: purchasesKey)
        }
    }

    private func loadPurchases() {
        guard let data = UserDefaults.standard.data(forKey: purchasesKey),
              let saved = try? JSONDecoder().decode([Purchase].self, from: data) else { return }
        purchases = saved
    }
}
