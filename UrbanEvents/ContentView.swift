import SwiftUI

struct ContentView: View {
    // Istanziamo il ViewModel mantenendolo in memoria
    @StateObject private var viewModel = EventsViewModel()

    var body: some View {
        TabView {
            ExploreView(viewModel: viewModel)
                .tabItem { Label("Esplora", systemImage: "safari") }

            EventsMapView(viewModel: viewModel)
                .tabItem { Label("Mappa", systemImage: "map") }
        }
        // Rende il ViewModel disponibile anche alle schermate di dettaglio (cuore, acquisto)
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
