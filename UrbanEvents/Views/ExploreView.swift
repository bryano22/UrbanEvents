import SwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: EventsViewModel
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // SEZIONE 1: Carosello Orizzontale (Eventi in Evidenza)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("In Evidenza")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.events) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        FeaturedCardView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    // Il cuore sta SOPRA il link: il tap non apre il dettaglio
                                    .overlay(alignment: .topTrailing) {
                                        FavoriteButton(event: event)
                                            .padding(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // SEZIONE 2: Lista Verticale Tutti gli Eventi
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tutti gli Eventi")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.events) { event in
                                HStack {
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventRowView(event: event)
                                    }
                                    .buttonStyle(.plain)

                                    FavoriteButton(event: event, style: .plain)
                                }
                                .padding(.horizontal)

                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Esplora")
            .toolbar {
                // Ingranaggio in alto a destra → Impostazioni
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("Impostazioni"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Subviews per mantenere il codice pulito

struct FeaturedCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading) {
            EventImage(url: event.imageURL)
                .frame(width: 240, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(event.title)
                .font(.headline)
                .lineLimit(1)

            Text(event.eventCategory.titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 240)
    }
}

struct EventRowView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            EventImage(url: event.imageURL)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(event.eventCategory.titleKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(event.date, format: .eventDate)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            Spacer()

            PriceText(price: event.price, isFree: event.isFree)
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(event.isFree ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundStyle(event.isFree ? .green : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .contentShape(Rectangle())
    }
}
