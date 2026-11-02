# SchieraXI per iPhone (repository `schieraxi-ios`): regole del progetto

App **nativa** (SwiftUI) per iPhone e iPad. Parla con il server di SchieraXI (API JSON; se il server si raggiunge solo con una VPN, la VPN deve essere accesa).
Il server e la logica (modello, formazioni, scambi) stanno nell'altro repository (`schieraxi`). Qui c'è solo l'app.
**Il `README.md` è la descrizione completa** (funzioni, architettura, come si compila, cosa provare sul telefono): leggilo prima di lavorarci.

## Dove e come si lavora
- Repository pubblico `tommaso-quatraro/schieraxi-ios`.
- Non c'è un Mac: si scrive qui su Windows e **GitHub Actions compila e prova su un Mac** (`macos-26`). Quello che non si può provare qui si prova lì.
- Flusso: **issue** → **ramo** → passi piccoli → **pull request** (`Closes #N`) → workflow `Test` verde → unione (squash) → build `Compila IPA` → prova sul telefono.
- Unisci la PR da solo quando i controlli sono verdi (guardando gli screenshot se la grafica cambia): l'utente ha dato autonomia, non serve chiedere. Se i controlli non partono (limite dell'account GitHub), dillo e aspetta: non unire a mano. Mai indirizzi, token o email nel repository (e' pubblico).
- La compilazione verde non prova il comportamento: la lista "Da provare sul telefono" è nel README. Non dire che una funzione va se non è provata.

## Regole del codice
- Struttura in `Sources/`: `Domain` (logica pura, facile da provare), `Data` (rete e disco), `Presentation/<Sezione>` (vista + ViewModel), `Support`, `App`.
  La logica nuova va in `Domain` con un test in `Tests/SchieraxiTests`; le viste hanno un `#Preview` con dati finti.
- I ViewModel ricevono un `ServerClient` nel costruttore (anteprime: `FinteServer`, test: `ServerDiProva`). Niente indirizzi veri nei test: solo `example.invalid`.
- Il progetto Xcode **non è in git**: lo genera XcodeGen da `project.yml`. Modifica `project.yml`, mai un `.xcodeproj`.
- Numeri e date sempre in italiano (`Formato`, `Quando`). Testi in italiano. Accessibilità: VoiceOver con frasi complete, aree di tocco da 44 pt, Dynamic Type.
- **Il repository è PUBBLICO, di proposito**: così GitHub Actions su macOS compila gratis e SideStore scarica gli aggiornamenti. Deciso il 29/10/2026: le fixture sono dati INVENTATI (squadre e giocatori fittizi, dal 31/10/2026): mai copiare risposte di una lega vera. Niente password, chiavi, indirizzi o dati personali veri (vedi "Chiavi e segreti").

## Chiavi e segreti
**Mai in git**: firme, certificati, profili, password, Apple ID. Nel repository e nell'IPA (entrambi pubblici) c'è UN SOLO indirizzo: quello predefinito, il dominio pubblico dell'app (`Config.indirizzoPredefinito`); mai un indirizzo privato o di rete privata. Chi ha un server proprio lo scrive in Lega > Server (o nell'area avanzata dell'accesso) e resta sul telefono. Il widget non chiede niente: indirizzo e token glieli passa l'app (App Group o Keychain condiviso), altrimenti usa il predefinito. Il workflow IPA fallisce se trova un indirizzo `ts.net` dentro l'IPA (non usa segreti). La modalità demo non ha password scritte nel codice.

## Installazione sul telefono
IPA non firmato dalla release `build-N`; lo firma e lo rinnova SideStore con l'Apple ID gratuito (certificato di 7 giorni, massimo 3 app, LocalDevVPN accesa).
Fonte per gli aggiornamenti: `https://github.com/tommaso-quatraro/schieraxi/releases/latest/download/sorgente.json` (repository unico). L'app cerca le nuove build leggendo l'ELENCO delle release e tenendo solo le `build-N`: nello stesso repository ci sono anche le release del server (`v1.x`, create con `--latest=false`).

## Passaggio al repository unico (`tommaso-quatraro/schieraxi`, app in `ios/`)
- I workflow di oggi (`ipa.yml`, `test.yml`, `screenshot.yml`) lavorano alla radice. Le copie per il repository unico stanno in `docs/ipa-repo-unico.yml` e `docs/ios-repo-unico.yml` (filtri `ios/**`, `working-directory: ios`): al passaggio vanno in `.github/workflows/` come `ipa.yml` (stesso nome) e `ios.yml`. In `ipa.yml` scrivere in `BASE_BUILD` l'ultima build già pubblicata.
- `scripts/genera_sorgente.py` accetta come 4° argomento la cartella dell'app (`ios`) per i percorsi delle icone.
- Release: le `build-N` dell'app con `--latest`; quelle del server `v1.x` con `--latest=false`, altrimenti rubano il «Latest» al sorgente di SideStore.
