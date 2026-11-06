import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.deviceDefault.rawValue
    @AppStorage("enableNotifications") private var enableNotifications = true

    @State private var showLoginDemoAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                // SEZIONE 1: Account (pulsanti SOLO di facciata)
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue.gradient)
                        Text("Accedi a UrbanEvents")
                            .font(.headline)
                        Text("Sincronizza preferiti e biglietti su tutti i tuoi dispositivi.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        // Sign in with Apple (finto)
                        Button {
                            showLoginDemoAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                Text("Accedi con Apple")
                            }
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        // Sign in with Google (finto)
                        Button {
                            showLoginDemoAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                GoogleLogo()
                                Text("Accedi con Google")
                            }
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.black)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Account")
                }

                // SEZIONE 2: Preferenze
                Section {
                    Picker(selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(verbatim: "\(language.flag) \(language.displayName)")
                                .tag(language.rawValue)
                        }
                    } label: {
                        Label("Lingua", systemImage: "globe")
                    }

                    Toggle(isOn: $enableNotifications) {
                        Label("Notifiche Eventi", systemImage: "bell.badge")
                    }
                } header: {
                    Text("Preferenze")
                }

                // SEZIONE 3: Info App
                Section {
                    LabeledContent("Versione App", value: appVersion)
                    LabeledContent {
                        Text(verbatim: "ITS Angelo Rizzoli")
                    } label: {
                        Text("Corso")
                    }
                } header: {
                    Text("Info Applicazione")
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .alert("Funzione non disponibile", isPresented: $showLoginDemoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Il login sarà disponibile in una prossima versione dell'app.")
            }
        }
    }
}

/// "G" colorata stile Google, disegnata con SwiftUI (nessun asset esterno)
private struct GoogleLogo: View {
    var body: some View {
        Text(verbatim: "G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(
                AngularGradient(colors: [.red, .yellow, .green, .blue, .red], center: .center)
            )
    }
}

#Preview {
    SettingsView()
}
