# SchieraXI per iPhone: regole del progetto

App **nativa** (SwiftUI) per iPhone e iPad. Parla con il server di SchieraXI sul Raspberry (API JSON, Tailscale acceso).
Il server e la logica (modello, formazioni, scambi) stanno nell'altro repository: `C:\Users\utente\Progetti\schieraxi`. Qui c'è solo l'app.
**Il `README.md` è la descrizione completa** (funzioni, architettura, come si compila, cosa provare sul telefono): leggilo prima di lavorarci.

## Dove e come si lavora
- Cartella `C:\Users\utente\Progetti\schieraxi-ios`, repository privato `tommaso-quatraro/schieraxi-ios`. Una sola copia, niente cloni doppi.
- Non c'è un Mac: si scrive qui su Windows e **GitHub Actions compila e prova su un Mac** (`macos-26`). Quello che non si può provare qui si prova lì.
- Flusso: **issue** → **ramo** → passi piccoli → **pull request** (`Closes #N`) → workflow `Test` verde → unione (squash) → build `Compila IPA` → prova sul telefono.
  Le regole valide per tutti i progetti stanno in `~\.claude\CLAUDE.md`.
- Unisci la PR solo con i test verdi e dopo il mio ok. Se i controlli non partono (limite dell'account GitHub), dillo: non unire a mano.
- La compilazione verde non prova il comportamento: la lista "Da provare sul telefono" è nel README. Non dire che una funzione va se non è provata.

## Regole del codice
- Struttura in `Sources/`: `Domain` (logica pura, facile da provare), `Data` (rete e disco), `Presentation/<Sezione>` (vista + ViewModel), `Support`, `App`.
  La logica nuova va in `Domain` con un test in `Tests/SchieraxiTests`; le viste hanno un `#Preview` con dati finti.
- I ViewModel ricevono un `ServerClient` nel costruttore (anteprime: `FinteServer`, test: `ServerDiProva`). Niente indirizzi veri nei test: solo `example.invalid`.
- Il progetto Xcode **non è in git**: lo genera XcodeGen da `project.yml`. Modifica `project.yml`, mai un `.xcodeproj`.
- Numeri e date sempre in italiano (`Formato`, `Quando`). Testi in italiano. Accessibilità: VoiceOver con frasi complete, aree di tocco da 44 pt, Dynamic Type.
- **Il repository è PUBBLICO, di proposito**: così GitHub Actions su macOS compila gratis e SideStore scarica gli aggiornamenti. Deciso il 29/10/2026: i nomi della lega nelle fixture non sono sensibili e restano. Niente password, chiavi, indirizzi o dati personali veri (vedi "Chiavi e segreti").

## Chiavi e segreti
**Mai in git**: firme, certificati, profili, password, Apple ID. L'indirizzo del server arriva dalle variabili del repository `FANTA_HOST` e `FANTA_PORT`, non sta nel codice.

## Installazione sul telefono
IPA non firmato dalla release `build-N`; lo firma e lo rinnova SideStore con l'Apple ID gratuito (certificato di 7 giorni, massimo 3 app, LocalDevVPN accesa).
Fonte per gli aggiornamenti: `.../releases/latest/download/sorgente.json`.
