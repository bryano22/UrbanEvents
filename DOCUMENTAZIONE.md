# UrbanEvents — Documentazione tecnica

> App iOS in **SwiftUI** (iOS 18) per scoprire, salvare, acquistare e creare eventi in città.
> Questo documento spiega **com'è organizzato il progetto**, **perché esiste ogni file**,
> **come i pezzi sono collegati** e **quali costrutti di Swift/SwiftUI sono usati e perché**.

---

## Indice

1. [Architettura: MVVM](#1-architettura-mvvm)
2. [Struttura delle cartelle](#2-struttura-delle-cartelle)
3. [Come sono collegati i pezzi (flusso dei dati)](#3-come-sono-collegati-i-pezzi)
4. [I file uno per uno](#4-i-file-uno-per-uno)
5. [Localizzazione italiano / inglese](#5-localizzazione-italiano--inglese)
6. [Glossario della sintassi Swift usata](#6-glossario-della-sintassi-swift-usata)
7. [Glossario SwiftUI / framework Apple](#7-glossario-swiftui--framework-apple)
8. [Errori tipici da evitare (visti in questo progetto)](#8-errori-tipici-da-evitare)

--- 

## 1. Architettura: MVVM

Il progetto segue il pattern **MVVM** (Model – View – ViewModel), quello consigliato per SwiftUI.

```
┌────────────┐      legge / osserva       ┌──────────────────┐      usa       ┌──────────┐
│   VIEW     │ ─────────────────────────▶ │    VIEWMODEL     │ ─────────────▶ │  MODEL   │
│ (SwiftUI)  │ ◀───────────────────────── │ EventsViewModel  │                │ Event,   │
│            │   @Published → ridisegna   │ (logica + stato) │                │ Purchase │
└────────────┘                            └──────────────────┘                └──────────┘
```

| Strato | Cosa contiene | Regola |
|---|---|---|
| **Model** | Le *strutture dati* pure (`Event`, `Purchase`, `EventCategory`, `AppLanguage`) | Non sa niente dell'interfaccia |
| **ViewModel** | Lo *stato* dell'app e le *azioni* (aggiungi preferito, acquista, crea evento, salvataggio) | Non disegna niente, espone dati |
| **View** | Le schermate SwiftUI | Mostrano i dati e chiamano i metodi del ViewModel |

**Perché?** Separare i ruoli rende il codice leggibile e modificabile: se domani i preferiti
venissero salvati su un server, cambi solo il ViewModel, le View restano uguali.

---

## 2. Struttura delle cartelle

```
UrbanEvents/
├── UrbanEventsApp.swift          ← punto di ingresso (@main), applica la lingua
├── ContentView.swift             ← TabView con le 4 schede, crea il ViewModel
│
├── Models/
│   ├── Event.swift               ← struct Event, enum EventCategory, struct Purchase
│   └── AppLanguage.swift         ← enum delle lingue supportate (it / en)
│
├── ViewModels/
│   └── EventsViewModel.swift     ← stato condiviso: eventi, preferiti, acquisti + persistenza
│
├── Views/
│   ├── ExploreView.swift         ← Home: carosello + lista + ingranaggio impostazioni
│   ├── EventDetailView.swift     ← Dettaglio evento + CheckoutView (acquisto)
│   ├── EventsMapView.swift       ← Mappa con i pin degli eventi
│   ├── AddEventView.swift        ← Form "Crea evento" + verifica indirizzo (geocoding)
│   ├── FavoritesView.swift       ← Preferiti + sezione "I miei acquisti" (biglietti)
│   ├── SettingsView.swift        ← Impostazioni: login finti, lingua, notifiche, info
│   └── Components.swift          ← Componenti riutilizzabili (cuore, immagine, prezzo…)
│
└── Resources/
    ├── Localizable.xcstrings     ← traduzioni italiano / inglese
    └── events_mock.json          ← eventi di esempio caricati all'avvio
```

> Il progetto Xcode usa le **cartelle sincronizzate** (Xcode 16+): ogni file `.swift`
> messo in queste cartelle viene compilato automaticamente, non serve "aggiungerlo" a mano.

---

## 3. Come sono collegati i pezzi

### 3.1 Chi crea cosa

```
UrbanEventsApp  (@main)
   │  .environment(\.locale, lingua scelta)      ← la lingua scende a TUTTE le view
   ▼
ContentView
   │  @StateObject viewModel = EventsViewModel()  ← UNICA istanza, vive finché vive l'app
   │  .environmentObject(viewModel)               ← la rende disponibile a tutti i "figli"
   ▼
TabView
   ├── ExploreView(viewModel:)      ──▶ NavigationLink ──▶ EventDetailView
   │        └── .sheet ──▶ SettingsView                         └── .sheet ──▶ CheckoutView
   ├── EventsMapView(viewModel:)    ──▶ .sheet ──▶ EventDetailView
   ├── AddEventView(viewModel:, onShowOnMap:)
   └── FavoritesView(viewModel:)    ──▶ NavigationLink ──▶ EventDetailView
```

### 3.2 Due modi di passare il ViewModel (entrambi usati, di proposito)

| Modo | Dove | Perché |
|---|---|---|
| **Parametro** `ExploreView(viewModel: viewModel)` + `@ObservedObject` | Le 4 schede | Dipendenza esplicita: si vede subito cosa usa la schermata |
| **Environment** `.environmentObject(viewModel)` + `@EnvironmentObject` | `EventDetailView`, `FavoriteButton` | Sono usati in tanti punti e a profondità diverse: passarli a mano ovunque sarebbe scomodo ("prop drilling") |

### 3.3 Esempio completo: l'utente tocca il cuore ❤️

1. `FavoriteButton` chiama `viewModel.toggleFavorite(event)`.
2. Il ViewModel inserisce/rimuove l'ID dal `Set<UUID>` `favoriteIDs`.
3. `favoriteIDs` è `@Published` → SwiftUI avvisa **tutte** le view che lo osservano.
4. Il suo `didSet` salva il Set in `UserDefaults` (persistenza).
5. Si ridisegnano da sole: il cuore (pieno/vuoto), la lista Preferiti, il badge sul tab,
   il colore del pin sulla mappa (rosso se preferito).

Nessuna view "avvisa" le altre: è il **binding reattivo** di SwiftUI che lo fa.

### 3.4 Esempio completo: creo un evento

1. `AddEventView` → l'utente scrive città e via → "Verifica indirizzo".
2. `verifyAddress()` (funzione `async`) usa `CLGeocoder` per trovare le coordinate.
3. Se tutto torna, salva un `ResolvedLocation` → appare l'anteprima della mappa.
4. "Aggiungi Evento" → crea un `Event` → `viewModel.addEvent(newEvent)`.
5. Il ViewModel lo aggiunge a `events` **e** imposta `eventToFocus = event`.
6. Alert → "Vedi sulla mappa" → la closure `onShowOnMap` cambia scheda (`selectedTab = .map`).
7. `EventsMapView` vede `eventToFocus`, centra la mappa sul pin e lo rimette a `nil`.

---

## 4. I file uno per uno

### 4.1 `UrbanEventsApp.swift`

```swift
@main
struct UrbanEventsApp: App {
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.deviceDefault.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
```

- `@main` → dice a Swift "il programma parte da qui".
- `App` / `Scene` / `WindowGroup` → struttura base di un'app SwiftUI.
- `@AppStorage` legge la lingua salvata; quando le Impostazioni la cambiano, questa
  proprietà cambia, `body` viene ricalcolato e la nuova `locale` scende a tutta l'app.

### 4.2 `ContentView.swift`

- Crea il ViewModel con **`@StateObject`** → garantisce che venga creato **una volta sola**
  (se usassi `@ObservedObject` qui, verrebbe ricreato a ogni ridisegno e perderesti i dati).
- `enum Tab` + `TabView(selection: $selectedTab)` + `.tag(...)` → permette di **cambiare
  scheda da codice** (serve al bottone "Vedi sulla mappa").
- `.badge(viewModel.favoriteIDs.count)` → numerino sul tab Preferiti (con 0 non si vede).

### 4.3 `Models/Event.swift`

**`struct Event`** — un evento.

```swift
struct Event: Identifiable, Hashable { ... }
extension Event: Codable { ... }
```

| Protocollo | Perché serve |
|---|---|
| `Identifiable` | Ha `id`: lo richiedono `ForEach`, `List`, `.sheet(item:)` |
| `Hashable` | Serve per confrontarlo (`onChange`) e usarlo come `tag` |
| `Codable` | Si converte da/verso JSON (`events_mock.json`) |

- `date` è un **`Date`** vero (prima era una `String`): così posso formattarla nella lingua
  dell'utente e impedire date passate.
- Il JSON però contiene `"15 Nov 2026 - 18:00"` → ho scritto a mano `init(from:)` ed
  `encode(to:)` che convertono la stringa con un `DateFormatter`.
- Il formatter ha locale `en_US_POSIX`: **fondamentale**, altrimenti su un iPhone in italiano
  "Nov" non verrebbe riconosciuto.
- Codable è in un'**extension** per un motivo preciso: se scrivi un `init` personalizzato
  *dentro* la struct, Swift smette di generarti l'init "memberwise"
  (`Event(id:title:...)`) che usiamo in `AddEventView`. Nell'extension, invece, lo conservi.
- `coordinate` ed `eventCategory` sono **computed property**: calcolate al volo, non salvate.

**`enum EventCategory: String, CaseIterable, Identifiable`** — le categorie.

- `String` come *raw value* → `case art = "Arte"`: il valore salvato nell'evento è "Arte".
- `CaseIterable` → ottieni gratis `EventCategory.allCases` per riempire il `Picker`.
- `icon` → un `switch` che restituisce il simbolo SF Symbols adatto.
- `titleKey: LocalizedStringKey` → la chiave da tradurre ("Arte" → "Art").

**`struct Purchase`** — un acquisto. Contiene una "fotografia" dei dati dell'evento
(titolo, data, immagine) così il biglietto resta visibile anche se l'evento sparisce.
`total` e `isFree` sono computed property.

### 4.4 `Models/AppLanguage.swift`

```swift
enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it"
    case english = "en"
    static let storageKey = "appLanguage"
    ...
}
```

- Centralizza le lingue: niente stringhe `"it"`/`"en"` sparse nel codice.
- `static let storageKey` → la chiave di `UserDefaults` è definita in **un solo posto**
  (usata sia in `UrbanEventsApp` sia in `SettingsView`).
- `deviceDefault` → al primo avvio usa la lingua del telefono se è it/en, altrimenti italiano.

### 4.5 `ViewModels/EventsViewModel.swift`

```swift
@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published private(set) var favoriteIDs: Set<UUID> = [] {
        didSet { saveFavorites() }
    }
    @Published private(set) var purchases: [Purchase] = [] {
        didSet { savePurchases() }
    }
    @Published var eventToFocus: Event?
    ...
}
```

| Elemento | Perché |
|---|---|
| `class` (non struct) | Deve essere **condiviso**: tutte le view devono vedere *lo stesso* oggetto (tipo riferimento) |
| `final` | Nessuno ne eredita → più chiaro e un po' più veloce |
| `ObservableObject` | Permette a SwiftUI di osservarlo |
| `@Published` | Ogni modifica fa ridisegnare le view che lo usano |
| `@MainActor` | Tutto il codice gira sul thread principale: l'interfaccia si aggiorna solo da lì |
| `private(set)` | Le view possono **leggere** ma non **modificare** direttamente: devono passare dai metodi (`toggleFavorite`, `purchase`). Così la logica sta in un posto solo |
| `didSet` | Ogni volta che il valore cambia → salvataggio automatico |
| `Set<UUID>` per i preferiti | Niente duplicati e `contains` velocissimo. Salvo solo gli ID, non gli eventi interi |

- `favoriteEvents` è una computed property: filtra `events` con gli ID preferiti.
- **Persistenza** con `UserDefaults`:
  - preferiti → array di stringhe (`uuidString`);
  - acquisti → `JSONEncoder` li trasforma in `Data`, `JSONDecoder` li rilegge.
- `ticketCount(for:)`, `totalTickets`, `totalSpent` usano `filter` e `reduce` (vedi glossario).

### 4.6 `Views/Components.swift` — mattoncini riutilizzabili

| Componente | A cosa serve |
|---|---|
| `FavoriteButton` | Il cuore. Usa `@EnvironmentObject` per raggiungere il ViewModel ovunque. Due stili (`.floating` sulle card, `.plain` nelle righe/toolbar) tramite un `enum Style` annidato. Animazione `withAnimation(.spring)`, `contentTransition(.symbolEffect(.replace))` per l'effetto sull'icona, `sensoryFeedback` per la vibrazione |
| `EventImage` | `AsyncImage` con gestione dei 3 stati (caricamento, successo, errore) |
| `CategoryBadge` | Etichetta colorata con icona + nome tradotto |
| `PriceText` | "Gratis" tradotto oppure il prezzo in € |
| `.eventDate` / `.euro` | Formati riutilizzabili per date e valuta (vedi §6.13) |

**Perché un file a parte?** Principio **DRY** (*Don't Repeat Yourself*): il cuore compare in
4 punti, se cambio il suo aspetto lo cambio una volta sola.

### 4.7 `Views/ExploreView.swift` — Home

- `NavigationStack` + `NavigationLink(destination:)` → navigazione verso il dettaglio.
- Carosello: `ScrollView(.horizontal)` + `HStack`.
- Lista: `LazyVStack` → crea le righe **solo quando servono** (performance con tanti eventi).
- Il cuore è in `.overlay(alignment: .topTrailing)` **fuori** dal `NavigationLink`:
  se fosse dentro, il tap aprirebbe anche il dettaglio.
- `.toolbar { ToolbarItem(placement: .topBarTrailing) { ... } }` → l'ingranaggio in alto a destra.
- `.sheet(isPresented: $showSettings) { SettingsView() }` → apre le impostazioni dal basso.
- `FeaturedCardView` ed `EventRowView` sono **sotto-view**: spezzano il codice in parti leggibili.

### 4.8 `Views/EventDetailView.swift` — Dettaglio + acquisto

- `@EnvironmentObject private var viewModel` → serve per preferiti e acquisti.
- Mini mappa: `Map(initialPosition:)` + `Marker`, con `.allowsHitTesting(false)` per renderla
  non interattiva (non "ruba" lo scroll).
- `Group { if ... else ... }` → per mostrare "Nessuna descrizione" tradotto quando è vuota.
- **`CheckoutView`**: schermata separata (sheet a metà schermo con `.presentationDetents([.medium])`).
  Riceve una **closure** `onConfirm: (Int) -> Void`: non sa *cosa* succede quando confermi,
  lo decide chi la apre. È il modo SwiftUI di far "rispondere" una view figlia alla madre.
- `@Environment(\.dismiss)` → chiude la sheet.

### 4.9 `Views/FavoritesView.swift` — Preferiti + Acquisti

- `List` con due `Section` (`header:` / `footer:`).
- Preferiti vuoti → `ContentUnavailableView` (schermata "vuoto" standard di iOS 17+).
- `.onDelete { viewModel.removeFavorites(at: $0) }` → swipe per eliminare.
- Acquisti → `TicketCardView`: card con `LinearGradient`, `ZStack`, linea tratteggiata
  (`Shape` personalizzata `Line` + `StrokeStyle(dash:)`), icona QR.
- `.listRowInsets(EdgeInsets())` → toglie i margini della riga per far scorrere il carosello
  da bordo a bordo.

### 4.10 `Views/SettingsView.swift` — Impostazioni

- `Form` con sezioni Account / Preferenze / Info.
- Bottoni Apple e Google **di facciata**: mostrano solo un `.alert`. Il logo Google è una "G"
  colorata con `AngularGradient` (nessuna immagine esterna).
- `Picker(selection: $appLanguage)` legato direttamente ad `@AppStorage`: cambi lingua → si
  salva da sola → `UrbanEventsApp` la rilegge → tutta l'app si traduce.
- `LabeledContent` → riga "etichetta a sinistra, valore a destra".
- Versione letta da `Bundle.main.infoDictionary` (non scritta a mano).

### 4.11 `Views/AddEventView.swift` — Crea evento

È la schermata più "logica". Punti chiave:

**Stato del form** — ogni campo è un `@State` legato al controllo con `$`:
```swift
@State private var title = ""
TextField("Titolo dell'evento", text: $title)
```

**Computed property di validazione**:
```swift
private var canSave: Bool { !trimmedTitle.isEmpty && resolvedLocation != nil && !isGeocoding }
```
Il bottone usa `.disabled(!canSave)`: impossibile salvare un evento senza indirizzo verificato.

**Geocoding in 3 passi** (`verifyAddress()`):
1. cerca la **città** → ottiene il nome ufficiale e le coordinate del centro;
2. cerca **"via, città"** limitando la ricerca a 25 km dal centro (`CLCircularRegion`);
3. controlla che `placemark.locality` sia **la stessa città** (confronto senza maiuscole/accenti)
   e che il risultato abbia una via (`thoroughfare`) o un luogo (`areasOfInterest`).

Usa `preferredLocale: it_IT` → così "Milan" e "Milano" vengono riconosciute come la stessa città.

**Errori come enum**:
```swift
enum LocationError: Equatable {
    case cityNotFound(String)
    case wrongCity(found: String, expected: String)
    ...
    @ViewBuilder var message: some View { switch self { ... } }
}
```
Ogni caso ha i suoi **valori associati** e il suo messaggio tradotto. Molto meglio di una `String`
di errore: il compilatore ti obbliga a gestire tutti i casi.

**Invalidazione**: `.onChange(of: address) { invalidateLocation() }` → se modifichi l'indirizzo
dopo averlo verificato, devi riverificarlo.

**Alert con dati**: `.alert(..., presenting: createdEvent) { event in ... }` → l'alert riceve
l'evento appena creato e lo usa nel messaggio.

### 4.12 `Views/EventsMapView.swift` — Mappa

- `@State var position: MapCameraPosition = .automatic` → la mappa inquadra **tutti** i pin.
- `Annotation` con un `Button` personalizzato (icona della categoria, rosso se preferito).
- `.sheet(item: $selectedEvent)` → quando `selectedEvent` non è `nil` si apre il dettaglio.
  Qui ripeto `.environmentObject(viewModel)` per sicurezza dentro la sheet.
- `focusIfNeeded()` è chiamata sia in `.onAppear` sia in `.onChange`: se la scheda Mappa non era
  mai stata aperta, `onChange` non scatterebbe, quindi serve anche `onAppear`.

---

## 5. Localizzazione italiano / inglese

### Come funziona

1. **`Localizable.xcstrings`** (String Catalog) contiene per ogni chiave la traduzione.
   La **lingua sorgente è l'italiano**: la chiave *è* il testo italiano, quindi per l'italiano
   non serve tradurre niente.
2. In SwiftUI, quando scrivi `Text("Preferiti")`, la stringa letterale diventa una
   **`LocalizedStringKey`** e viene cercata nel catalogo.
3. La lingua usata è quella dell'environment: `.environment(\.locale, ...)` in `UrbanEventsApp`.
4. Anche date (`Text(date, format:)`) e prezzi (`Text(price, format: .euro)`) seguono la locale:
   "15 nov 2026, 18:00" ↔ "Nov 15, 2026 at 6:00 PM", "10,00 €" ↔ "€10.00".

### Interpolazione e plurali

```swift
Text("\(viewModel.totalTickets) biglietti")
```
diventa la chiave `"%lld biglietti"` (`%lld` = intero, `%@` = stringa).
Nel catalogo ha le **varianti plurali**: `one` → "1 biglietto" / "1 ticket",
`other` → "3 biglietti" / "3 tickets".

Con due argomenti l'inglese usa `%1$@` e `%2$@` (argomenti numerati) così, se una lingua
inverte l'ordine delle parole, la traduzione funziona lo stesso.

### Quando NON tradurre

```swift
Text(verbatim: "ITS Angelo Rizzoli")   // testo fisso, non va nel catalogo
Text(event.title)                       // variabile String → mostrata così com'è
```

---

## 6. Glossario della sintassi Swift usata

### 6.1 `struct` vs `class`
```swift
struct Event { ... }                 // TIPO VALORE: ogni copia è indipendente
final class EventsViewModel { ... }  // TIPO RIFERIMENTO: tutti puntano allo stesso oggetto
```
Model → `struct` (dati semplici, sicuri). ViewModel → `class` (stato condiviso).
Le View SwiftUI sono sempre `struct`: leggere, vengono ricreate di continuo.

### 6.2 `let` / `var`
`let` = costante, `var` = variabile. Le proprietà di `Event` sono tutte `let`: un evento non cambia
dopo la creazione.

### 6.3 Optional `?`, `if let`, `guard let`, `??`
```swift
@State private var resolvedLocation: ResolvedLocation?   // può essere nil

if let resolvedLocation { LocationPreview(...) }          // "se c'è, usalo" (sintassi breve Swift 5.7)

guard let cityMark = cityResults.first else {             // "se NON c'è, esci subito"
    locationError = .cityNotFound(trimmedCity)
    return
}

let ids = UserDefaults.standard.stringArray(forKey: key) ?? []  // valore di default se nil
```
`guard` evita la "piramide" di `if` annidati: gestisci prima i casi d'errore, poi il codice buono.

### 6.4 Computed property
```swift
var total: Double { unitPrice * Double(quantity) }
```
Non occupa memoria: viene calcolata ogni volta che la leggi. Sempre aggiornata.

### 6.5 Property observer `didSet`
```swift
@Published private(set) var favoriteIDs: Set<UUID> = [] {
    didSet { saveFavorites() }
}
```
Codice eseguito **dopo** ogni modifica del valore.

### 6.6 Controllo d'accesso
- `private` → visibile solo nel file/tipo.
- `private(set)` → leggibile da fuori, modificabile solo da dentro.

### 6.7 `enum` con raw value, `switch`, valori associati
```swift
enum EventCategory: String { case art = "Arte" }         // raw value
EventCategory(rawValue: "Arte")                         // → .art (oppure nil)

enum LocationError { case wrongCity(found: String, expected: String) }  // valori associati

switch self {
case .wrongCity(let found, let expected): ...
}
```
Lo `switch` in Swift deve essere **esaustivo**: se aggiungi un caso, il compilatore ti segnala
tutti i punti da aggiornare.

### 6.8 Protocolli e conformità
`Identifiable`, `Codable`, `Hashable`, `Equatable`, `CaseIterable`, `ObservableObject`, `View`, `Shape`.
Un protocollo è un "contratto": dichiari la conformità e Swift spesso genera il codice da solo
(es. `Hashable` e `Codable` automatici se tutte le proprietà li supportano).

### 6.9 Extension
```swift
extension Event: Codable { ... }
extension FormatStyle where Self == Date.FormatStyle { static var eventDate ... }
```
Aggiungono funzionalità a un tipo (anche di Apple) senza modificarlo.
`where Self == ...` = "vale solo per quel tipo specifico" (extension **vincolata**).

### 6.10 Closure e `$0`
```swift
events.filter { favoriteIDs.contains($0.id) }      // $0 = primo parametro
purchases.reduce(0) { $0 + $1.quantity }           // $0 = accumulatore, $1 = elemento
var onShowOnMap: () -> Void = {}                   // closure come proprietà (callback)
let onConfirm: (Int) -> Void
```
**Trailing closure**: se l'ultimo parametro è una closure la scrivi fuori dalle parentesi
(`Button { azione } label: { aspetto }`).

### 6.11 Funzioni di ordine superiore
| Funzione | Cosa fa | Dove |
|---|---|---|
| `filter` | tiene gli elementi che rispettano la condizione | `favoriteEvents` |
| `map` | trasforma ogni elemento | `favoriteIDs.map(\.uuidString)` |
| `compactMap` | trasforma e scarta i `nil` | `ids.compactMap(UUID.init(uuidString:))` |
| `reduce` | riduce a un solo valore | `totalSpent` |
| `first(where:)` | primo elemento che rispetta la condizione | geocoding |

`\.uuidString` è un **key path**: un riferimento a una proprietà, usato come funzione.

### 6.12 `async` / `await` / `Task` / `do-catch`
```swift
Button { Task { await verifyAddress() } } label: { ... }

private func verifyAddress() async {
    isGeocoding = true
    defer { isGeocoding = false }            // eseguito SEMPRE all'uscita dalla funzione
    do {
        let results = try await geocoder.geocodeAddressString(...)
    } catch let error as CLError where error.code == .network {
        locationError = .network             // errore specifico
    } catch {
        locationError = .addressNotFound     // qualsiasi altro errore
    }
}
```
- `async` = la funzione può "aspettare" senza bloccare l'interfaccia.
- `await` = punto in cui si aspetta il risultato (la rete).
- `Task { }` = avvia codice asincrono da un contesto normale (il tap di un bottone).
- `try` = la chiamata può lanciare un errore; `do/catch` lo gestisce.
- `defer` = garantisce che lo spinner si spenga anche se la funzione esce prima con `return`.

Prima il codice usava le **completion handler** (`geocode... { placemarks, error in ... }`
+ `DispatchQueue.main.async`): `async/await` è la versione moderna, lineare e più leggibile.

### 6.13 Format style
```swift
Text(event.date, format: .eventDate)
Text(price, format: .euro)
```
Invece di `String(format: "%.2f €", price)` (fisso, non localizzato) usiamo i formati di
Foundation, che si adattano alla lingua. `.eventDate` ed `.euro` sono **membri statici**
che abbiamo definito noi in `Components.swift`.

### 6.14 `@MainActor`
Indica che il codice gira sul **thread principale**. Le modifiche all'interfaccia (e alle
proprietà `@Published`) devono avvenire lì, altrimenti si hanno warning o crash.

### 6.15 `static`
Proprietà/metodi del **tipo**, non della singola istanza:
`Event.storageDateFormatter` (creato una volta sola, i `DateFormatter` sono costosi),
`AppLanguage.storageKey`, `AddEventView.defaultImageURL`.

---

## 7. Glossario SwiftUI / framework Apple

### 7.1 Property wrapper di stato — **la parte più importante**

| Wrapper | Chi possiede il dato | Usato in |
|---|---|---|
| `@State` | la view stessa (dato semplice e locale) | campi del form, `showSettings`, `selectedTab` |
| `@Binding` / `$var` | qualcun altro; `$` crea un collegamento in lettura+scrittura | `TextField(text: $title)`, `Toggle(isOn: $isFree)` |
| `@StateObject` | la view **crea e possiede** un oggetto | `ContentView` (crea il ViewModel) |
| `@ObservedObject` | l'oggetto arriva **da fuori** come parametro | le 4 schede |
| `@EnvironmentObject` | l'oggetto arriva dall'**environment** | `EventDetailView`, `FavoriteButton` |
| `@Environment(\.x)` | valori di sistema | `\.dismiss`, `\.locale` |
| `@AppStorage("key")` | `UserDefaults`, persiste tra gli avvii | lingua, notifiche |
| `@Published` | proprietà di un `ObservableObject` che notifica i cambiamenti | ViewModel |

Regola pratica: **chi crea usa `@StateObject`, chi riceve usa `@ObservedObject`/`@EnvironmentObject`.**

### 7.2 Layout
`VStack` (verticale), `HStack` (orizzontale), `ZStack` (sovrapposti), `LazyVStack` (pigro),
`Spacer` (spinge), `ScrollView`, `List`, `Form`, `Section`, `Group`.

### 7.3 Modificatori
Si concatenano e **l'ordine conta**:
```swift
.padding().background(Color.blue)   // sfondo che include il padding
.background(Color.blue).padding()   // padding fuori dallo sfondo
```
Usati: `.font`, `.foregroundStyle`, `.padding`, `.frame`, `.background`, `.overlay`,
`.clipShape`, `.shadow`, `.disabled`, `.badge`, `.textCase`, `.lineLimit`, ecc.

> Ho sostituito i vecchi `.foregroundColor` e `.cornerRadius` (deprecati) con
> `.foregroundStyle` e `.clipShape(RoundedRectangle(cornerRadius:))`.

### 7.4 Navigazione e presentazione
| API | Uso |
|---|---|
| `NavigationStack` + `NavigationLink` | push verso il dettaglio |
| `.toolbar { ToolbarItem(placement:) }` | bottoni nella barra (ingranaggio, cuore, Fine) |
| `.sheet(isPresented:)` / `.sheet(item:)` | schermata modale dal basso |
| `.presentationDetents([.medium])` | sheet a metà altezza |
| `.alert(...)` | popup di conferma/errore |
| `TabView(selection:)` + `.tag` + `.tabItem` | schede in basso |

### 7.5 Eventi del ciclo di vita
`.onAppear { }` (la view compare), `.onChange(of: valore) { }` (un valore cambia).

### 7.6 `@ViewBuilder` e `some View`
- `some View` = "restituisco *un certo* tipo di View, il compilatore sa quale" (opaque type).
- `@ViewBuilder` permette di usare `if`/`switch` per restituire view diverse
  (`LocationError.message`).

### 7.7 Altri componenti
`AsyncImage` (immagini da URL), `ContentUnavailableView` (stato vuoto), `LabeledContent`,
`Stepper`, `DatePicker(in: Date()...)` (range = solo date future), `Picker`, `Toggle`,
`TextEditor`, `LinearGradient`, `AngularGradient`, `Shape` personalizzate, SF Symbols
(`Image(systemName:)`).

### 7.8 Framework
| Framework | Uso |
|---|---|
| **SwiftUI** | interfaccia |
| **Foundation** | `Date`, `UUID`, `UserDefaults`, `JSONDecoder`, `Bundle`, `Locale` |
| **MapKit** | `Map`, `Marker`, `Annotation`, `MapCameraPosition`, `MKCoordinateRegion` |
| **CoreLocation** | `CLGeocoder` (indirizzo → coordinate), `CLPlacemark`, `CLCircularRegion` |

---

## 8. Errori tipici da evitare

1. **Ternario con stringhe → niente traduzione**
   ```swift
   Text(isFree ? "Prenota" : "Acquista")                    // ❌ diventa String: NON tradotto
   Text(isFree ? LocalizedStringKey("Prenota") : "Acquista") // ✅ tradotto
   ```
2. **`@ObservedObject` per creare un oggetto** → viene ricreato e perdi i dati. Usa `@StateObject`.
3. **Bottone dentro un `NavigationLink`** → il tap apre anche il dettaglio. Mettilo in `.overlay`.
4. **Parsare date con la locale del telefono** → su iPhone in italiano "Nov" fallisce.
   Usa `en_US_POSIX` per i formati "tecnici".
5. **Geocoding senza controllo** → "Via Roma 1" può finire in un'altra città.
   Specifica città, regione di ricerca e verifica `locality`.
6. **Fallback silenziosi** (prima: indirizzo non trovato → evento messo a Milano) → l'utente
   non sa che qualcosa è andato storto. Meglio un errore chiaro.
7. **Formattare prezzi con `String(format:)`** → non si adatta alla lingua. Usa `format: .currency`.

---

*Documento generato per il progetto UrbanEvents — ITS Angelo Rizzoli.*
