import Foundation

/// Lingue supportate dall'app. Il valore viene salvato in @AppStorage("appLanguage")
/// e applicato a tutta l'interfaccia tramite `.environment(\.locale, ...)` in UrbanEventsApp.
enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it"
    case english = "en"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// Nome mostrato sempre nella propria lingua (convenzione iOS)
    var displayName: String {
        switch self {
        case .italian: return "Italiano"
        case .english: return "English"
        }
    }

    var flag: String {
        switch self {
        case .italian: return "🇮🇹"
        case .english: return "🇬🇧"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }

    /// Lingua iniziale: quella del dispositivo se supportata, altrimenti italiano
    static var deviceDefault: AppLanguage {
        let code = Locale.preferredLanguages.first.flatMap { Locale(identifier: $0).language.languageCode?.identifier }
        return AppLanguage(rawValue: code ?? "") ?? .italian
    }

}
