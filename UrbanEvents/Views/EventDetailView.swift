import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject private var viewModel: EventsViewModel

    @State private var showCheckout = false
    @State private var showConfirmationAlert = false

    private var ticketsOwned: Int { viewModel.ticketCount(for: event) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Immagine Copertina
                Color.clear
                    .frame(height: 250)
                    .overlay(EventImage(url: event.imageURL))
                    .clipped()

                // Contenuto Testuale
                VStack(alignment: .leading, spacing: 12) {

                    // Categoria e Data
                    HStack {
                        CategoryBadge(category: event.eventCategory)
                        Spacer()
                        Text(event.date, format: .eventDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Titolo
                    Text(event.title)
                        .font(.title)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)

                    // VIA / INDIRIZZO DELL'EVENTO
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.red)
                        Text(event.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Mini mappa con la posizione
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: event.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))) {
                        Marker(event.title, coordinate: event.coordinate)
                    }
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)

                    Divider()

                    // Descrizione
                    Text("Informazioni sull'evento")
                        .font(.headline)

                    Group {
                        if event.description.isEmpty {
                            Text("Nessuna descrizione disponibile.")
                        } else {
                            Text(event.description)
                        }
                    }
                    .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    if ticketsOwned > 0 {
                        Label {
                            Text("Hai già \(ticketsOwned) biglietti per questo evento")
                        } icon: {
                            Image(systemName: "ticket.fill")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    }

                    Spacer(minLength: 20)

                    // Box Prezzo e Acquisto
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Prezzo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            PriceText(price: event.price, isFree: event.isFree)
                                .font(.title2)
                                .bold()
                        }

                        Spacer()

                        Button {
                            showCheckout = true
                        } label: {
                            Text(event.isFree ? LocalizedStringKey("Prenota Posto") : "Acquista Biglietto")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: 180)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(event: event, style: .plain)
            }
        }
        .sheet(isPresented: $showCheckout) {
            CheckoutView(event: event) { quantity in
                viewModel.purchase(event, quantity: quantity)
                showCheckout = false
                showConfirmationAlert = true
            }
            .presentationDetents([.medium])
        }
        .alert(event.isFree ? LocalizedStringKey("Prenotazione confermata!") : "Acquisto effettuato!", isPresented: $showConfirmationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Trovi i tuoi biglietti nella sezione Preferiti.")
        }
    }
}

// MARK: - Checkout (scelta quantità)

struct CheckoutView: View {
    let event: Event
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        EventImage(url: event.imageURL)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title).font(.headline)
                            Text(event.date, format: .eventDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Stepper(value: $quantity, in: 1...10) {
                        HStack {
                            Text("Biglietti")
                            Spacer()
                            Text(verbatim: "\(quantity)").bold()
                        }
                    }
                    HStack {
                        Text("Totale")
                        Spacer()
                        PriceText(price: event.price * Double(quantity), isFree: event.isFree)
                            .bold()
                    }
                }

                Section {
                    Button {
                        onConfirm(quantity)
                    } label: {
                        Text(event.isFree ? LocalizedStringKey("Conferma Prenotazione") : "Conferma Acquisto")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(event.isFree ? LocalizedStringKey("Prenota") : "Acquista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
}
