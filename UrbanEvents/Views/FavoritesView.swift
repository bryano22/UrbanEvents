import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: EventsViewModel

    var body: some View {
        NavigationStack {
            List {
                // SEZIONE 1: Eventi preferiti (VUOTA DI DEFAULT)
                Section {
                    if viewModel.favoriteEvents.isEmpty {
                        ContentUnavailableView {
                            Label("Nessun preferito", systemImage: "heart.slash")
                        } description: {
                            Text("Tocca il cuore su un evento per salvarlo qui.")
                        }
                    } else {
                        ForEach(viewModel.favoriteEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                FavoriteRow(event: event)
                            }
                        }
                        .onDelete { viewModel.removeFavorites(at: $0) }
                    }
                } header: {
                    Text("I Miei Eventi Preferiti")
                } footer: {
                    if !viewModel.favoriteEvents.isEmpty {
                        Text("Scorri verso sinistra per rimuovere un evento.")
                    }
                }

                // SEZIONE 2: I miei acquisti (piccola sezione a "biglietti")
                Section {
                    if viewModel.purchases.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "ticket")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Non hai ancora acquistato biglietti.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.purchases) { purchase in
                                    TicketCardView(purchase: purchase)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    HStack {
                        Text("I Miei Acquisti")
                        Spacer()
                        if !viewModel.purchases.isEmpty {
                            // Riepilogo: "3 biglietti · 45,00 €"
                            HStack(spacing: 4) {
                                Text("\(viewModel.totalTickets) biglietti")
                                Text(verbatim: "·")
                                Text(viewModel.totalSpent, format: .euro)
                            }
                            .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle("Preferiti")
        }
    }
}

// MARK: - Riga evento preferito

private struct FavoriteRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            EventImage(url: event.imageURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(event.date, format: .eventDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(event.address, systemImage: "mappin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Card "biglietto" per gli acquisti

struct TicketCardView: View {
    let purchase: Purchase

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Parte superiore: immagine + titolo
            ZStack(alignment: .bottomLeading) {
                EventImage(url: purchase.eventImageURL)
                    .frame(width: 220, height: 90)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                Text(purchase.eventTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(10)
            }
            .frame(width: 220, height: 90)

            // Linea tratteggiata "strappo"
            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(.white.opacity(0.6))
                .frame(height: 1)
                .padding(.horizontal, 10)
                .padding(.top, 8)

            // Parte inferiore: dettagli
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.eventDate, format: .eventDate)
                        .font(.caption)
                    HStack(spacing: 4) {
                        Text(verbatim: "x\(purchase.quantity)")
                            .font(.caption.bold())
                        Text(verbatim: "·")
                        PriceText(price: purchase.total, isFree: purchase.isFree)
                            .font(.caption.bold())
                    }
                }
                Spacer()
                Image(systemName: "qrcode")
                    .font(.system(size: 30))
            }
            .foregroundStyle(.white)
            .padding(10)
        }
        .frame(width: 220)
        .background(
            LinearGradient(colors: purchase.isFree ? [.green, .teal] : [.blue, .purple],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
