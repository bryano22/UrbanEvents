import SwiftUI

struct ContentView: View {
    // Istanziamo il ViewModel mantenendolo in memoria
    @StateObject private var viewModel = EventsViewModel()

    enum Tab: Hashable { case explore, map, create, favorites }
    @State private var selectedTab: Tab = .explore

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView(viewModel: viewModel)
                .tabItem { Label("Esplora", systemImage: "safari") }
                .tag(Tab.explore)

            EventsMapView(viewModel: viewModel)
                .tabItem { Label("Mappa", systemImage: "map") }
                .tag(Tab.map)

            AddEventView(viewModel: viewModel, onShowOnMap: { selectedTab = .map })
                .tabItem { Label("Crea", systemImage: "plus.circle") }
                .tag(Tab.create)

            FavoritesView(viewModel: viewModel)
                .tabItem { Label("Preferiti", systemImage: "heart") }
                .tag(Tab.favorites)
                .badge(viewModel.favoriteIDs.count)
        }
        // Rende il ViewModel disponibile anche alle schermate di dettaglio (cuore, acquisto)
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
