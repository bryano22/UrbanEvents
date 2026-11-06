import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text(verbatim: "UrbanEvents")
                .font(.largeTitle.bold())
        }
    }
}

#Preview {
    ContentView()
}
