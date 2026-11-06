import SwiftUI
import CoreLocation
import MapKit

struct AddEventView: View {
    @ObservedObject var viewModel: EventsViewModel
    /// Chiamata dal bottone "Vedi sulla mappa" dopo la creazione
    var onShowOnMap: () -> Void = {}

    private static let defaultImageURL = "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=800"

    // Campi del form
    @State private var title: String = ""
    @State private var category: EventCategory = .art
    @State private var city: String = "Milano"
    @State private var address: String = ""
    @State private var description: String = ""
    @State private var eventDate: Date = Date().addingTimeInterval(60 * 60 * 24)
    @State private var isFree: Bool = false
    @State private var price: Double = 10.0
    @State private var imageURL: String = AddEventView.defaultImageURL

    // Stato verifica indirizzo
    @State private var isGeocoding = false
    @State private var resolvedLocation: ResolvedLocation?
    @State private var locationError: LocationError?

    // Stato creazione
    @State private var createdEvent: Event?

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCity: String { city.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedAddress: String { address.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canVerify: Bool { !trimmedCity.isEmpty && !trimmedAddress.isEmpty && !isGeocoding }
    private var canSave: Bool { !trimmedTitle.isEmpty && resolvedLocation != nil && !isGeocoding }

    var body: some View {
        NavigationStack {
            Form {
                // SEZIONE 1: Info Generali
                Section(header: Text("Informazioni Evento")) {
                    TextField("Titolo dell'evento", text: $title)

                    Picker("Categoria", selection: $category) {
                        ForEach(EventCategory.allCases) { cat in
                            Label(cat.titleKey, systemImage: cat.icon).tag(cat)
                        }
                    }

                    TextField("URL Immagine", text: $imageURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // SEZIONE 2: Luogo e Indirizzo (con verifica sulla mappa)
                Section {
                    TextField("Città", text: $city)
                        .textContentType(.addressCity)
                    TextField("Via e numero civico (es. Via Dante 5)", text: $address)
                        .textContentType(.fullStreetAddress)

                    Button {
                        Task { await verifyAddress() }
                    } label: {
                        HStack {
                            Label("Verifica indirizzo sulla mappa", systemImage: "location.magnifyingglass")
                            Spacer()
                            if isGeocoding { ProgressView() }
                        }
                    }
                    .disabled(!canVerify)

                    if let resolvedLocation {
                        LocationPreview(location: resolvedLocation, title: trimmedTitle)
                    }

                    if let locationError {
                        Label {
                            locationError.message
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Luogo")
                } footer: {
                    if resolvedLocation == nil {
                        Text("Verifica l'indirizzo per poter creare l'evento.")
                    }
                }

                // SEZIONE 3: Data e Ora (solo date future)
                Section(header: Text("Data e Ora")) {
                    DatePicker("Seleziona data", selection: $eventDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }

                // SEZIONE 4: Prezzo e Biglietto
                Section(header: Text("Prezzo e Biglietto")) {
                    Toggle("Evento Gratuito", isOn: $isFree.animation())

                    if !isFree {
                        Stepper(value: $price, in: 1...500, step: 0.5) {
                            HStack {
                                Text("Prezzo biglietto:")
                                Spacer()
                                Text(price, format: .euro)
                                    .bold()
                            }
                        }
                    }
                }

                // SEZIONE 5: Descrizione
                Section(header: Text("Descrizione")) {
                    TextEditor(text: $description)
                        .frame(height: 100)
                }

                // SEZIONE 6: Bottone di Salvataggio
                Section {
                    Button(action: saveEvent) {
                        Text("Aggiungi Evento")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(canSave ? Color.blue : Color.gray.opacity(0.5))
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Crea Evento")
            // Se l'utente modifica città o indirizzo, la verifica precedente non vale più
            .onChange(of: city) { invalidateLocation() }
            .onChange(of: address) { invalidateLocation() }
            .alert("Evento Creato!", isPresented: Binding(
                get: { createdEvent != nil },
                set: { if !$0 { createdEvent = nil } }
            ), presenting: createdEvent) { _ in
                Button("Vedi sulla mappa") {
                    resetForm()
                    onShowOnMap()
                }
                Button("OK", role: .cancel) {
                    resetForm()
                }
            } message: { event in
                Text("L'evento '\(event.title)' in '\(event.address)' è stato aggiunto ed è posizionato sulla Mappa.")
            }
        }
    }

    // MARK: - Geocoding

    private func invalidateLocation() {
        resolvedLocation = nil
        locationError = nil
    }

    /// 1) Trova la città  2) cerca l'indirizzo DENTRO quella città
    /// 3) controlla che il risultato sia davvero nella città indicata e sia preciso (via/luogo).
    private func verifyAddress() async {
        guard canVerify else { return }
        isGeocoding = true
        defer { isGeocoding = false }
        invalidateLocation()

        // Usiamo sempre l'italiano per i nomi restituiti, così "Milan" e "Milano" coincidono
        let italian = Locale(identifier: "it_IT")
        let geocoder = CLGeocoder()

        do {
            // 1) Città
            let cityResults = try await geocoder.geocodeAddressString(trimmedCity, in: nil, preferredLocale: italian)
            guard let cityMark = cityResults.first,
                  let cityLocation = cityMark.location,
                  let cityName = cityMark.locality ?? cityMark.name else {
                locationError = .cityNotFound(trimmedCity)
                return
            }

            // 2) Indirizzo, con la città come contesto e regione di ricerca
            let region = CLCircularRegion(center: cityLocation.coordinate, radius: 25_000, identifier: "city")
            let results = try await geocoder.geocodeAddressString("\(trimmedAddress), \(cityName)",
                                                                  in: region,
                                                                  preferredLocale: italian)

            // 3) Deve trovarsi nella città giusta
            guard let match = results.first(where: { Self.sameCity($0.locality, cityName) }) else {
                if let otherCity = results.first?.locality {
                    locationError = .wrongCity(found: otherCity, expected: cityName)
                } else {
                    locationError = .addressNotFound
                }
                return
            }

            // ... e deve essere un indirizzo preciso, non solo il centro città
            let hasStreet = match.thoroughfare != nil
            let hasPlace = !(match.areasOfInterest ?? []).isEmpty
            guard hasStreet || hasPlace, let location = match.location else {
                locationError = .notPrecise
                return
            }

            resolvedLocation = ResolvedLocation(
                coordinate: location.coordinate,
                formattedAddress: Self.format(match, city: cityName)
            )
        } catch let error as CLError where error.code == .network {
            locationError = .network
        } catch {
            locationError = .addressNotFound
        }
    }

    private static func sameCity(_ a: String?, _ b: String) -> Bool {
        guard let a else { return false }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return a.compare(b, options: options) == .orderedSame
    }

    /// Es. "Via Dante 5, 20121 Milano" oppure "Castello Sforzesco, Milano"
    private static func format(_ placemark: CLPlacemark, city: String) -> String {
        var street: String
        if let thoroughfare = placemark.thoroughfare {
            street = thoroughfare
            if let number = placemark.subThoroughfare { street += " \(number)" }
        } else {
            street = placemark.areasOfInterest?.first ?? placemark.name ?? ""
        }
        let cityPart = [placemark.postalCode, city].compactMap { $0 }.joined(separator: " ")
        return [street, cityPart].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    // MARK: - Salvataggio

    private func saveEvent() {
        guard canSave, let location = resolvedLocation else { return }

        let trimmedURL = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let validURL = URL(string: trimmedURL)?.scheme?.hasPrefix("http") == true ? trimmedURL : Self.defaultImageURL

        let newEvent = Event(
            id: UUID(),
            title: trimmedTitle,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.rawValue,
            address: location.formattedAddress,
            date: eventDate,
            price: isFree ? 0.0 : price,
            isFree: isFree,
            imageURL: validURL,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        viewModel.addEvent(newEvent)
        createdEvent = newEvent
    }

    private func resetForm() {
        title = ""
        category = .art
        address = ""
        description = ""
        eventDate = Date().addingTimeInterval(60 * 60 * 24)
        isFree = false
        price = 10.0
        imageURL = Self.defaultImageURL
        invalidateLocation()
    }
}

// MARK: - Modelli di supporto

struct ResolvedLocation: Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let formattedAddress: String

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

enum LocationError: Equatable {
    case cityNotFound(String)
    case addressNotFound
    case wrongCity(found: String, expected: String)
    case notPrecise
    case network

    @ViewBuilder var message: some View {
        switch self {
        case .cityNotFound(let city):
            Text("Città \"\(city)\" non trovata.")
        case .addressNotFound:
            Text("Indirizzo non trovato. Controlla via e numero civico.")
        case .wrongCity(let found, let expected):
            Text("L'indirizzo trovato si trova a \(found), non a \(expected).")
        case .notPrecise:
            Text("Indirizzo poco preciso: specifica la via e il numero civico.")
        case .network:
            Text("Impossibile verificare l'indirizzo: controlla la connessione.")
        }
    }
}

// MARK: - Anteprima posizione

private struct LocationPreview: View {
    let location: ResolvedLocation
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))) {
                Marker(title.isEmpty ? location.formattedAddress : title, coordinate: location.coordinate)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .id(location.id) // ricrea la mappa a ogni nuova verifica

            Label(location.formattedAddress, systemImage: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddEventView(viewModel: EventsViewModel())
        .environmentObject(EventsViewModel())
}
