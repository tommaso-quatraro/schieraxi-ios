# MAPPA: SchieraXI per iPhone/iPad, repository `schieraxi-ios`

Leggi prima `CLAUDE.md` e, per le funzioni, `README.md` (lungo: cerca con Grep, non leggerlo tutto). Ultimo aggiornamento: 30/10/2026.
Il server e la logica stanno in `schieraxi` (`C:\Users\utente\Progetti\schieraxi`, ha la sua MAPPA.md con i contratti delle API). Qui c'e' solo l'app SwiftUI.

## Comandi
- NON c'e' un Mac: non si compila ne' si prova in locale. Tutto gira su GitHub Actions (`macos-26`, Xcode 26).
- Test = workflow `Test` (`.github/workflows/test.yml`): a ogni push e PR, `xcodegen generate` + `xcodebuild test -scheme Schieraxi` su un simulatore scelto da `scripts/scegli_simulatore.py`. Attesa: `gh pr checks N --watch --interval 30`. Se rosso: `gh run view --log-failed` (restano anche gli artifact `risultati-test`, 7 giorni).
- IPA = workflow `Compila IPA` (`ipa.yml`): parte a ogni push su `main` (e a mano), crea la release `build-N` con `Schieraxi.ipa` e `sorgente.json` (`scripts/genera_sorgente.py`). Fonte per SideStore: `.../releases/latest/download/sorgente.json`.
- Foto delle schermate: workflow `screenshot.yml` (a mano o a ogni push su main che cambia `Sources/`); scaricare con `gh run download <id> --name screenshot-app --dir .screenshot` (cartella ignorata da git).
- Attenzione ai costi: macOS e' il runner piu' caro. Il repository e' pubblico di proposito proprio perche' cosi' le Actions su macOS sono gratis (e SideStore scarica gli aggiornamenti). Non renderlo privato. Evita push inutili (un push = una corsa di test + una di screenshot/IPA su main); fai piu' modifiche per push e usa le PR.
- Il progetto Xcode non e' in git: lo genera XcodeGen da `project.yml`. Modifica `project.yml`, mai un `.xcodeproj`.

## Cartelle e file (`Sources/`)
- `App\` ingresso: `SchieraxiApp.swift`, `AppModel.swift` (crea una volta i ViewModel), `Radice.swift` (schede/barra laterale, scheda del giocatore, aspetto).
- `Domain\` logica pura e testabile: `Modelli.swift`, `Modelli2.swift`, `Modelli3.swift` (risposte del server), `Quando` (date, ora italiana), `Formato` (numeri in italiano), `Forma`, `GiocatoreEtichette`, `ConfrontoLogica`, `ScambiLogica`, `RegoleLogica`, `TestoFormazione`.
- `Data\` rete e disco: `ServerClient.swift` (protocollo + `ServerHTTP` + `FinteServer`, `IndirizzoServer`, `ErroreApi`), `Caricatore.swift` (`Stato<T>`), `Cache.swift` (offline, `Caches/api`), `Immagini.swift`, `OggiRepository.swift`, `Accesso.swift` (token nel Keychain), `Account.swift`.
- `Presentation\<Sezione>\` vista + ViewModel: `Oggi`, `Formazione`, `Mercato` (+ scheda giocatore, asta), `Confronto`, `Scambi`, `Lega` (squadre, regole, avvisi, gestione, guide), `Accesso` (login/account/recupero). Base: `ViewModelBase.swift`.
- `Support\` componenti e servizi: `Componenti`, `RigaGiocatore`, `CampoFormazione`, `Grafici`, `Aspetto`, `Notifiche`, `Aggiornamento` (background), `Spotlight`, `Comandi` (Siri/App Intents), `Certificato` (scadenza SideStore), `Collegamenti` (`schieraxi://`), `NuovaVersione`, demo (`Demo`, `DatiDemo`, `DemoImmagini`, `DatiAnteprima`).
- `Support\Design\` design system: `Tema`, `Carta`, `Sfondo`, `Stati`, `Vetro` (Liquid Glass: tutto iOS 26 passa da qui dietro `#available`), `Marchio`, `Voce`, `Zoom`, `Protezione`, `AccessorioGiornata`.
- `WidgetSources\` target widget `SchieraxiWidget`. `Tests\SchieraxiTests` (XCTest, fixture vere in `Tests\Fixtures\*.json`), `Tests\SchieraxiUITests` (XCUITest con `-DEMO`). `scripts\` aiuti per la CI. `project.yml` e' la fonte unica del progetto (target, bundle id, Info.plist generato).

## Convenzioni
- Logica nuova in `Domain` con test in `Tests/SchieraxiTests`; ogni vista ha un `#Preview` con dati finti (`FinteServer`).
- I ViewModel ricevono un `ServerClient` nel costruttore (anteprime `FinteServer`, test `ServerDiProva`). Nei test solo indirizzi `example.invalid`, mai quelli veri.
- Testi in italiano, numeri e date con `Formato` e `Quando`. Accessibilita': VoiceOver con frasi complete, aree di tocco 44 pt, Dynamic Type, "Ridurre movimento".
- Funzioni di iOS 26 solo tramite `Vetro` e `#available`: il target minimo e' iOS 18.
- Flusso: issue, ramo, passi piccoli, PR (`Closes #N`), `Test` verde, unione squash (`gh pr merge N --squash --delete-branch`) SOLO con ok dell'utente, poi build IPA e prova sul telefono. Se i controlli non partono (limite account) si aspetta: non si unisce a mano.
- La compilazione verde non prova il comportamento: la lista "Da provare sul telefono" e' nel README. Non dire che una funzione va se non e' provata.
- Il disco in cartella e' in CRLF per molti file (autocrlf su Windows), nel repository e' LF: non riscrivere interi file solo per i fine riga; controlla `git diff --stat`.

## Parlare con il server
- Indirizzo: variabili/segreti del repository `FANTA_HOST` e `FANTA_PORT` (iniettati in `Info.plist` come `FantaHost`/`FantaPort` da `project.yml`; nel file i valori sono `example.invalid`/`443`). Modificabile da Lega, solo `https://` (`http` solo verso localhost). Mai l'indirizzo vero nel codice, nei test o nei log.
- Ogni richiesta che non e' GET/HEAD manda `X-Fanta: 1` (il server altrimenti risponde 403). Errori: `{"detail": "..."}` gia' in italiano, mostrati cosi' come sono.
- Account (server con `FANTA_MULTIUTENTE=1`): login con `nativo: true`, il token torna nel corpo e si manda come `Authorization: Bearer`; sta SOLO nel Keychain (mai UserDefaults, mai log). 401 = serve accesso (`ErroreApi.accessoRichiesto`), 429 con `Retry-After` = troppi tentativi.
- Il server si aggiorna da solo su un Raspberry: aggiungere campi e' sicuro, togliere o rinominare campi rompe l'app gia' installata. Decodifica tollerante (campi nuovi opzionali). Le fixture in `Tests/Fixtures` si rifanno col server locale del repo `schieraxi`.
- Modifiche di contratto: farle prima lato server (retrocompatibili), poi qui.
- Offline: l'ultima risposta di ogni schermata e' in `Caches/api` (max 150 file, per server); "Server non raggiungibile. Dati salvati del ...".

## Da NON cambiare (rompe SideStore/aggiornamenti/dati dell'utente)
- Bundle id `it.tommaso.schieraxi` (e `it.tommaso.schieraxi.aggiorna` per il task in background, estensione widget col suo id): cambiarlo = app nuova, perso il rinnovo e l'App ID gratuito (limite 3 app, il widget ne usa uno in piu').
- Schema URL `schieraxi://` (`oggi`, `formazione`, `mercato`, `scambi`, `lega`, `giocatore/<id>`): usato dalle notifiche ntfy con intestazione `Click`.
- Nomi interni invariati dopo il rebranding a SchieraXI: target `Schieraxi`, `Schieraxi.ipa`, repository. Cambia solo `CFBundleDisplayName: SchieraXI`.
- Nomi delle icone alternative (`AppIcon-blu|viola|arancio|rosso|grafite`) in `project.yml` e nell'asset catalog: il workflow IPA controlla che siano dichiarate.
- I target di test NON devono finire nell'IPA (controllato dal workflow). `Config/Info.plist` e' generato e ignorato da git.

## Punti delicati
- Mai in git: firme, certificati, profili, password, Apple ID, indirizzo del Pi. Le fixture hanno i nomi di una lega reale: accettato il 29/10/2026 (repo pubblico).
- Installazione: IPA non firmato, lo firma SideStore con Apple ID gratuito: certificato 7 giorni, max 3 app, LocalDevVPN accesa, una sola VPN alla volta. Nessuna notifica push (APNs): avvisi via ntfy + `schieraxi://`.
- Se SideStore protesta per i limiti, si toglie il target `SchieraxiWidget` e la riga `dependencies` da `project.yml`.
- Modalita' demo: argomento di lancio `-DEMO` (+ `-DEMO_SCHERMATA`, `-DEMO_FONDO`, `-DEMO_ORIENTAMENTO`, `-DEMO_CERCA`); in demo l'indirizzo vero non compare e il Keychain non si usa. I test UI e gli screenshot dipendono da questo: non romperlo.
- Concorrenza dei workflow: `test.yml` annulla le corse vecchie dello stesso ramo; `ipa.yml` ha bisogno di `contents: write` per la release.
