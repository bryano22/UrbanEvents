import SwiftUI

// MARK: - Bottone cuore riutilizzabile (card, righe, dettaglio)

struct FavoriteButton: View {
    @EnvironmentObject private var viewModel: EventsViewModel
    let event: Event
    var style: Style = .floating

    enum Style { case floating, plain }

    private var isFavorite: Bool { viewModel.isFavorite(event) }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                viewModel.toggleFavorite(event)
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(style == .floating ? .subheadline.bold() : .body)
                .foregroundStyle(isFavorite ? .red : (style == .floating ? .white : .primary))
                .padding(style == .floating ? 8 : 0)
                .background {
                    if style == .floating {
                        Circle().fill(.black.opacity(0.35))
                    }
                }
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isFavorite)
        .accessibilityLabel(isFavorite ? Text("Rimuovi dai preferiti") : Text("Aggiungi ai preferiti"))
    }
}

// MARK: - Immagine remota con placeholder

struct EventImage: View {
    let url: String

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            default:
                ZStack {
                    Color.gray.opacity(0.1)
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Badge categoria tradotto

struct CategoryBadge: View {
    let category: EventCategory

    var body: some View {
        Label(category.titleKey, systemImage: category.icon)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Formattazioni comuni (usano la lingua dell'environment)

extension FormatStyle where Self == Date.FormatStyle {
    /// Es. "15 nov 2026, 18:00" / "Nov 15, 2026 at 6:00 PM"
    static var eventDate: Date.FormatStyle {
        .dateTime.day().month(.abbreviated).year().hour().minute()
    }
}

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var euro: FloatingPointFormatStyle<Double>.Currency { .currency(code: "EUR") }
}

/// Testo prezzo: "Gratis" tradotto oppure valuta formattata
struct PriceText: View {
    let price: Double
    let isFree: Bool

    var body: some View {
        if isFree {
            Text("Gratis")
        } else {
            Text(price, format: .euro)
        }
    }
}
