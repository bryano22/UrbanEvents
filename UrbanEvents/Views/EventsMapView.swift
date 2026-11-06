import SwiftUI
import MapKit

struct EventsMapView: View {
    @ObservedObject var viewModel: EventsViewModel

    // .automatic = inquadra tutti gli eventi (anche se sono in città diverse)
    @State private var position: MapCameraPosition = .automatic

    // Per gestire l'apertura del dettaglio quando l'utente fa tap su un pin
    @State private var selectedEvent: Event?

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(viewModel.events) { event in
                    // Marker personalizzato sulla mappa
                    Annotation(event.title, coordinate: event.coordinate) {
                        Button {
                            selectedEvent = event
                        } label: {
                            Image(systemName: event.eventCategory.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(viewModel.isFavorite(event) ? Color.red : Color.blue))
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(radius: 2)
                        }
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .navigationTitle("Mappa Eventi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { position = .automatic }
                    } label: {
                        Image(systemName: "scope")
                    }
                    .accessibilityLabel(Text("Mostra tutti gli eventi"))
                }
            }
            // Centra la mappa sull'evento appena creato
            .onAppear(perform: focusIfNeeded)
            .onChange(of: viewModel.eventToFocus) { focusIfNeeded() }
            // Mostra la vista di dettaglio tramite sheet quando viene selezionato un pin
            .sheet(item: $selectedEvent) { event in
                NavigationStack {
                    EventDetailView(event: event)
                }
                .environmentObject(viewModel)
            }
        }
    }

    private func focusIfNeeded() {
        guard let event = viewModel.eventToFocus else { return }
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: event.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
        viewModel.eventToFocus = nil
    }
}

#Preview {
    let viewModel = EventsViewModel()
    return EventsMapView(viewModel: viewModel)
        .environmentObject(viewModel)
}
