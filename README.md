# UrbanEvents

App iOS in **SwiftUI** per scoprire, salvare e creare eventi in città.
Progetto del corso ITS Angelo Rizzoli.

## Funzionalità
- **Esplora**: eventi in evidenza e lista completa
- **Mappa**: tutti gli eventi sulla mappa, con dettaglio al tap
- **Crea evento**: form con verifica dell'indirizzo sulla mappa (città corretta)
- **Preferiti**: eventi salvati con il cuore e storico dei biglietti acquistati
- **Impostazioni**: lingua italiano/inglese, notifiche, login Apple/Google (demo)

## Requisiti
- Xcode 16 o successivo
- iOS 18

## Avvio
1. Apri `UrbanEvents.xcodeproj`
2. Scegli un simulatore iPhone
3. Premi ▶︎ (⌘R)

## Struttura
```
UrbanEvents/
├── Models/        → dati (Event, Purchase, categorie, lingue)
├── ViewModels/    → stato e logica dell'app
├── Views/         → schermate SwiftUI
└── Resources/     → traduzioni e dati di esempio
```

La spiegazione completa è in `DOCUMENTAZIONE.md`.
