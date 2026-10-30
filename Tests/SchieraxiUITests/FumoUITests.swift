import XCTest

/// Test di fumo dell'interfaccia: l'app parte in modalità demo (dati finti, senza rete), le cinque sezioni si raggiungono
/// e le schermate principali mostrano il testo atteso. Si cerca per testo (etichetta di accessibilità), non per posizione.
final class FumoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-DEMO", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
    }

    /// Un elemento qualsiasi (testo, pulsante, riga) con quell'etichetta, anche solo contenuta.
    private func elemento(_ testo: String, contiene: Bool = false) -> XCUIElement {
        let predicato = NSPredicate(format: contiene ? "label CONTAINS[c] %@" : "label ==[c] %@", testo)
        return app.descendants(matching: .any).matching(predicato).firstMatch
    }

    private func attendi(_ testo: String, contiene: Bool = false, secondi: TimeInterval = 20, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(elemento(testo, contiene: contiene).waitForExistence(timeout: secondi), "non compare «\(testo)»", file: file, line: line)
    }

    /// Per le liste: le righe fuori dallo schermo non esistono ancora, quindi si scorre finché compare l'elemento.
    private func attendiScorrendo(_ testo: String, contiene: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            if elemento(testo, contiene: contiene).waitForExistence(timeout: 2) { return }
            app.swipeUp()
        }
        XCTFail("non compare «\(testo)» nemmeno scorrendo", file: file, line: line)
    }

    private func vaiA(_ sezione: String) {
        let barra = app.tabBars.firstMatch
        XCTAssertTrue(barra.waitForExistence(timeout: 30), "la barra delle sezioni deve comparire")
        barra.buttons[sezione].firstMatch.tap()   // con iOS 26 la barra a volte espone due elementi per la stessa scheda
    }

    func testLeCinqueSezioniSonoRaggiungibili() {
        let barra = app.tabBars.firstMatch
        XCTAssertTrue(barra.waitForExistence(timeout: 30), "la barra delle sezioni deve comparire")
        for nome in ["Oggi", "Formazione", "Mercato", "Scambi", "Lega"] {
            XCTAssertTrue(barra.buttons[nome].exists, "manca la sezione \(nome)")
        }
    }

    func testOggiMostraLaGiornataELaFormazione() {
        attendi("La tua formazione")
        attendi("Da controllare")
        attendi("Apri la formazione")
        attendi("punti attesi", contiene: true)
        XCTAssertTrue(app.navigationBars["Oggi"].exists)
    }

    func testFormazioneConCampoEModificaAMano() {
        vaiA("Formazione")
        attendi("Campo")
        attendi("Stile")
        attendi("Panchina")
        let modifica = app.buttons["Modifica a mano"]
        XCTAssertTrue(modifica.waitForExistence(timeout: 20), "il pulsante «Modifica a mano» deve esserci")
        modifica.tap()
        attendi("Salva come mia scelta")
        attendi("Torna alla consigliata")
        app.buttons["Torna alla consigliata"].tap()
        XCTAssertTrue(app.buttons["Modifica a mano"].waitForExistence(timeout: 20), "tornando alla consigliata ricompare «Modifica a mano»")
    }

    func testMercatoSezioni() {
        vaiA("Mercato")
        attendi("Svincolati che migliorano la squadra")
        for sezione in ["Consigliati", "Giocatori", "Osservati", "Calendario"] {
            XCTAssertTrue(app.buttons[sezione].waitForExistence(timeout: 10), "manca la sezione \(sezione) del Mercato")
        }
        XCTAssertFalse(app.buttons["Asta"].exists, "l'asta sta in Lega")
        app.buttons["Giocatori"].tap()
        attendi("Solo svincolati")
    }

    func testScambiConOffertaEAnalisi() {
        vaiA("Scambi")
        XCTAssertTrue(app.buttons["Cerca scambi"].waitForExistence(timeout: 20), "le proposte si cercano con il pulsante")
        attendi("Ho ricevuto un'offerta")
        attendi("Chi accetta più volentieri")
        attendi("Analizza uno scambio a mano")
    }

    func testLegaConLeNuovePagine() {
        vaiA("Lega")
        attendi("Aggiorna i dati")
        for voce in ["Aggiorna le rose", "Squadre e rose", "Movimenti e storico", "Asta e riparazione", "Regole", "Aspetto", "Icona dell'app"] {
            attendiScorrendo(voce, contiene: true)
        }
        elemento("Aspetto").tap()
        attendi("Colore principale")
        attendiScorrendo("Animazioni ridotte", contiene: true)
    }

    func testSchedaDiUnGiocatoreSiApreEDiChiude() {
        // un tocco su una riga di Oggi apre la scheda (foglio) con la previsione, la forma e il grafico dei voti
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'punti attesi'")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 30), "serve almeno una riga di giocatore in Oggi")
        riga.tap()
        attendi("Prossima partita")
        attendi("Forma")
        let chiudi = app.buttons["Chiudi"]
        XCTAssertTrue(chiudi.waitForExistence(timeout: 10))
        chiudi.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    func testUnCsvDelleRoseSiImportaDaUnAltraApp() {
        // la demo scrive un CSV vero (separatore «;») e lo importa come se arrivasse da «Apri con SchieraXI»
        app.terminate()
        app.launchArguments += ["-DEMO_SCHERMATA", "lega-importa-csv"]
        app.launch()
        attendi("Cosa è cambiato")
        XCTAssertFalse(elemento("Usa un Excel (.xlsx), un CSV o un file di testo.").exists, "il CSV non deve essere rifiutato")
    }

    func testLaLenteApreLaRicerca() {
        let lente = app.buttons["Cerca un giocatore"]
        XCTAssertTrue(lente.waitForExistence(timeout: 30), "la lente della ricerca deve esserci in Oggi")
        lente.tap()
        attendi("Scrivi almeno due lettere del nome.")
    }
}
