# MAPPA: SchieraXI per iPhone/iPad, repository `schieraxi-ios`

Leggi prima `CLAUDE.md` e, per le funzioni, `README.md` (lungo: cerca con Grep, non leggerlo tutto). Ultimo aggiornamento: 1/11/2026.
Il server e la logica stanno nel repository `schieraxi` (ha la sua MAPPA.md con i contratti delle API). Qui c'e' solo l'app SwiftUI.

## Comandi
- NON c'e' un Mac: non si compila ne' si prova in locale. Tutto gira su GitHub Actions (`macos-26`, Xcode 26).
- Test = workflow `Test` (`.github/workflows/test.yml`): su ogni PR e su push a main (non sui rami), `xcodegen generate` + `xcodebuild test -scheme Schieraxi` su un simulatore scelto da `scripts/scegli_simulatore.py`. Attesa: `gh pr checks N --watch --interval 30`. Se rosso: `gh run view --log-failed` (restano anche gli artifact `risultati-test`, 7 giorni).
- IPA = workflow `Compila IPA` (`ipa.yml`): parte a ogni push su `main` che cambia `Sources/`, `WidgetSources/`, `Config/`, `project.yml` o gli script dell'IPA (e a mano), crea la release `build-N` con `Schieraxi.ipa` e `sorgente.json` (`scripts/genera_sorgente.py`). Fonte per SideStore: `.../releases/latest/download/sorgente.json`.
- Foto delle schermate: workflow `screenshot.yml` (app e widget in un job; a mano, o con l'etichetta `screenshot` sulla PR, o se la PR cambia schermate/widget; vedi README «CI»); scaricare con `gh run download <id> --name screenshot-app --dir .screenshot` (cartella ignorata da git).
- Attenzione ai costi: macOS e' il runner piu' caro. Il repository e' pubblico di proposito proprio perche' cosi' le Actions su macOS sono gratis (e SideStore scarica gli aggiornamenti). Non renderlo privato. Evita push inutili (un push = una corsa di test + una di screenshot/IPA su main); fai piu' modifiche per push e usa le PR.
- Il progetto Xcode non e' in git: lo genera XcodeGen da `project.yml`. Modifica `project.yml`, mai un `.xcodeproj`.

## Cartelle e file (`Sources/`)
- `App\` ingresso: `SchieraxiApp.swift`, `AppModel.swift` (crea una volta i ViewModel), `Radice.swift` (schede/barra laterale, scheda del giocatore, aspetto).
- `Domain\` logica pura e testabile: `Modelli.swift`, `Modelli2.swift`, `Modelli3.swift` (risposte del server), `Quando` (date, ora italiana), `Formato` (numeri in italiano), `Forma`, `GiocatoreEtichette`, `ConfrontoLogica`, `ScambiLogica`, `RegoleLogica`, `TestoFormazione`.
- `Data\` rete e disco: `ServerClient.swift` (protocollo + `ServerHTTP` + `FinteServer`, `IndirizzoServer`, `ErroreApi`), `Caricatore.swift` (`Stato<T>`), `Cache.swift` (offline, `Caches/api`), `Immagini.swift`, `OggiRepository.swift`, `Accesso.swift` (token nel Keychain), `Account.swift`, `Versioni.swift` (ETag delle risorse personali: `If-Match` automatico in `ServerHTTP`; 412 = `ErroreApi.conflitto`, la schermata ricarica).
- `Presentation\<Sezione>\` vista + ViewModel: `Oggi`, `Formazione`, `Mercato` (+ scheda giocatore, asta), `Confronto`, `Scambi`, `Lega` (squadre, regole, avvisi, gestione, guide), `Accesso` (login/account/recupero). Base: `ViewModelBase.swift`.
- `Support\` componenti e servizi: `Componenti`, `RigaGiocatore`, `CampoFormazione`, `Grafici`, `Aspetto`, `Notifiche`, `Aggiornamento` (background), `Spotlight`, `Comandi` (Siri/App Intents), `Certificato` (scadenza SideStore), `Collegamenti` (`schieraxi://`), `NuovaVersione`, demo (`Demo`, `DatiDemo`, `DemoImmagini`, `DatiAnteprima`).
- `Support\Design\` design system: `Tema`, `Carta`, `Sfondo`, `Stati`, `Vetro` (Liquid Glass: tutto iOS 26 passa da qui dietro `#available`), `Marchio`, `Voce`, `Zoom`, `Protezione`, `AccessorioGiornata`.
- `WidgetSources\` target widget `SchieraxiWidget`. `Tests\SchieraxiTests` (XCTest, fixture vere in `Tests\Fixtures\*.json`), `Tests\SchieraxiUITests` (XCUITest con `-DEMO`). `scripts\` aiuti per la CI. `project.yml` e' la fonte unica del progetto (target, bundle id, Info.plist generato).

## Convenzioni
- Logica nuova in `Domain` con test in `Tests/SchieraxiTests`; ogni vista ha un `#Preview` con dati finti (`FinteServer`).
- I ViewModel ricevono un `ServerClient` nel costruttore (anteprime `FinteServer`, test `ServerDiProva`). Nei test solo indirizzi `example.invalid`, mai quelli veri.
- Testi in italiano, numeri e date con `Formato` e `Quando`. Accessibilita': VoiceOver con frasi complete, aree di tocco 44 pt, Dynamic Type, "Ridurre movimento".
- Funzioni di iOS 26 solo tramite `Vetro` e `#available`: il target minimo e' iOS 18.
- Flusso: issue, ramo, passi piccoli, PR (`Closes #N`), `Test` verde, unione squash (`gh pr merge N --squash --delete-branch`) appena `Test` e' verde (autonomia data dall'utente; screenshot guardati se la grafica cambia), poi build IPA e prova sul telefono. Se i controlli non partono (limite account) si aspetta: non si unisce a mano.
- La compilazione verde non prova il comportamento: la lista "Da provare sul telefono" e' nel README. Non dire che una funzione va se non e' provata.
- Il disco in cartella e' in CRLF per molti file (autocrlf su Windows), nel repository e' LF: non riscrivere interi file solo per i fine riga; controlla `git diff --stat`.

## Parlare con il server
- Indirizzo: nell'app e nel repository (pubblici) c'e' SOLO il predefinito, il dominio pubblico dell'app (`Config.indirizzoPredefinito`, mai chiesto all'utente). Chi ha un server proprio lo scrive in Lega > Server (`ProvaServerView`, con prova prima di salvare) o nell'area avanzata dell'accesso, in `UserDefaults` chiave `indirizzo`; solo `https://` (`http` solo verso localhost). Il widget lo ha nelle sue impostazioni (`ConfigurazioneWidget`). Mai l'indirizzo vero nel codice, nei test o nei log; l'IPA non lo contiene (controllo nel workflow). Un segreto `FANTA_HOST` serve solo a quel controllo.
- Ogni richiesta che non e' GET/HEAD manda `X-Fanta: 1` (il server altrimenti risponde 403). Errori: `{"detail": "..."}` gia' in italiano, mostrati cosi' come sono.
- Account (server con `FANTA_MULTIUTENTE=1`): login con `nativo: true`, il token torna nel corpo e si manda come `Authorization: Bearer`; sta SOLO nel Keychain (mai UserDefaults, mai log). 401 = serve accesso (`ErroreApi.accessoRichiesto`), 429 con `Retry-After` = troppi tentativi.
- Il server si aggiorna da solo: aggiungere campi e' sicuro, togliere o rinominare campi rompe l'app gia' installata. Decodifica tollerante (campi nuovi opzionali). Le fixture in `Tests/Fixtures` sono dati inventati: se la struttura cambia si aggiornano a mano.
- Ore tranquille (`silenzio`, `silenzio_da`, `silenzio_a` degli avvisi): `Domain/OreTranquille.swift`; i promemoria locali le rispettano (le ricorda in UserDefaults). Il nome e' sempre «SchieraXI» con XI maiuscolo. Con «Riduci movimento»: dissolvenze e onda di opacita', mai movimenti (`Tema.molla/morbida/quieta`, `.transizione`).
- Modifiche di contratto: farle prima lato server (retrocompatibili), poi qui.
- Offline: l'ultima risposta di ogni schermata e' in `Caches/api` (max 150 file, per server); "Server non raggiungibile. Dati salvati del ...".

## Da NON cambiare (rompe SideStore/aggiornamenti/dati dell'utente)
- Bundle id `it.schieraxi.app` (dal 1/11/2026, prima `it.tommaso.schieraxi`; e `it.schieraxi.app.aggiorna` per il task in background, estensione widget col suo id): cambiarlo = app nuova, perso il rinnovo e l'App ID gratuito (limite 3 app, il widget ne usa uno in piu').
- Schema URL `schieraxi://` (`oggi`, `formazione`, `mercato`, `scambi`, `lega`, `giocatore/<id>`, e `social?codice=...` / `social?errore=...` che riceve solo la finestra di accesso con Google): usato dalle notifiche ntfy con intestazione `Click`.
- Bundle id, App Group, schema, target e IPA usano lo slug `schieraxi`. Il cambio di bundle id (31/10/2026) ha reso l'app una app NUOVA per SideStore: accesso da rifare, widget da riaggiungere, la vecchia app va cancellata a mano. Nessuna compatibilita' con i nomi di prima: schemi e formati di copia di sicurezza vecchi non si leggono piu' (controllo in `NomeVecchioTests`).
- Una sola icona (`AppIcon`): dal 1/11/2026 niente icone alternative; il workflow IPA controlla che nell'Info.plist non ce ne siano.
- I target di test NON devono finire nell'IPA (controllato dal workflow). `Config/Info.plist` e' generato e ignorato da git.

## Punti delicati
- Mai in git: firme, certificati, profili, password, Apple ID, indirizzo del server. Le fixture sono dati inventati (squadre e giocatori fittizi).
- Installazione: IPA non firmato, lo firma SideStore con Apple ID gratuito: certificato 7 giorni, max 3 app, LocalDevVPN accesa, una sola VPN alla volta. Nessuna notifica push (APNs): avvisi via ntfy + `schieraxi://`.
- App Group (indirizzo, token e ultimo riassunto condivisi col widget): `Sources/Support/Condiviso.swift`. Con l'Apple ID gratuito funziona se i permessi sono dentro l'IPA (ldid in `ipa.yml`) e SideStore scrive il nome vero in Info.plist `ALTAppGroups`: l'app lo legge a runtime. NON provato su un telefono vero: se il widget chiede ancora l'accesso o l'indirizzo, il gruppo non e' stato registrato (ripiego: indirizzo nelle impostazioni del widget).
- Se SideStore protesta per i limiti, si toglie il target `SchieraxiWidget` e la riga `dependencies` da `project.yml`.
- Modalita' demo: argomento di lancio `-DEMO` (+ `-DEMO_SCHERMATA`, `-DEMO_FONDO`, `-DEMO_ORIENTAMENTO`, `-DEMO_CERCA`); in demo l'indirizzo vero non compare e il Keychain non si usa. I test UI e gli screenshot dipendono da questo: non romperlo.
- Concorrenza dei workflow: ogni workflow ha il gruppo `workflow + ramo` e annulla la corsa vecchia; su `main` `ipa.yml` NON annulla la build in corso (può essere la release). `ipa.yml` ha bisogno di `contents: write` per la release.

## Impostazioni e Altro (ripulite il 1/11/2026)
- Impostazioni (`Presentation/Lega/ImpostazioniView.swift`): Il tuo account (`AccountSezione`: un solo nome, email di Google se manca quella dell'account, `Domain/ProfiloAccount.swift`), Accessi, App (Aspetto: tema e animazioni; Avvisi), Informazioni (privacy, termini, licenze, versione), Avanzate (solo chi amministra; il widget si collega da solo tramite App Group e token `fw_`: nessun codice da copiare, resta solo la diagnostica), Esci (`EsciSezione`).
- Altro (`LegaView`, `ambito: .altro`): Scambi, Diario, Asta, Regole, Movimenti, Crediti, Nuova stagione, Novità. Ogni voce in un posto solo; niente pallino sulle schede (le novità le annuncia la riga di Oggi).
- Tolti: «Sotto il cofano», copia di sicurezza nell'interfaccia (schermata e logica di invio tolte; il «Da fare» `backup` non si mostra), icone alternative, colore/densità/sezione iniziale (`OpzioniTolte` toglie le scelte vecchie all'avvio), maiuscole del nome, esci da tutti i telefoni.

## Accesso con Google (1/11/2026)
- Il giro lo fa il SERVER; l'app apre nel browser di sistema (`ASWebAuthenticationSession`, `Support/AvvioWeb.swift`, niente SDK di Google) l'indirizzo di `POST /api/account/social/google/inizia`, riceve `schieraxi://social?codice=...` e lo riscatta con `POST .../social/scambio` (codice monouso di 60 secondi + verificatore PKCE, che resta solo in memoria). Nessun identificativo di Google nel codice.
- I pulsanti compaiono SOLO se il server dichiara `social: ["google"]` (nel 401 e in `/api/account/me`): si ricorda in `ServiziSociali` (UserDefaults `serviziSociali`). Spento = tutto invisibile.
- Logica pura e testata: `Domain/AccessoSocial.swift` (PKCE, ritorno, risposte tolleranti, frasi dei codici d'errore). Sessione: `SessioneAccount` (`accediConGoogle`, `completaConGoogle`, `collegaGoogle`, `riconfermaGoogle`, `scollegaGoogle`, `impostaPassword`). Schermate: `Presentation/Accesso/AccessoGoogleView.swift`.
- Errori del server con campo `codice` -> `ErroreApi.codificato` (es. `serve_riconferma`, `ultimo_accesso`, `email_gia_usata`).

## Repository unico (passaggio)
- App dentro `tommaso-quatraro/schieraxi`, cartella `ios/`. Copie dei workflow per quel repository: `docs/ipa-repo-unico.yml` (-> `.github/workflows/ipa.yml`, con `BASE_BUILD`) e `docs/ios-repo-unico.yml` (-> `ios.yml`). Sorgente SideStore: `https://github.com/tommaso-quatraro/schieraxi/releases/latest/download/sorgente.json`.
- `NuovaVersione` legge l'elenco `releases?per_page=30` e prende la `build-N` piu' alta (`tagPiuAlto`), ignorando le release `v1.x` del server. `ipa.yml` non usa segreti. Modalita' demo (`-DEMO_ACCESSO`): la password si compone a caso, non e' scritta nel codice.
