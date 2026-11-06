//
//  UrbanEventsApp.swift
//  UrbanEvents
//
//  Created by d4 on 06/11/26.
//

import SwiftUI

@main
struct UrbanEventsApp: App {
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.deviceDefault.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Applica la lingua scelta a TUTTA l'app (testi, date, prezzi, DatePicker...).
                // Cambiandola dalle Impostazioni l'interfaccia si aggiorna subito.
                .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
