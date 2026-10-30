import XCTest

/// La schermata di accesso e il resto dell'account, con l'app in modalità demo (`-DEMO_ACCESSO <scenario>`): server finto, nessuna rete.
final class AccessoUITests: XCTestCase {
    private var app: XCUIApplication!

    private func avvia(_ scenario: String) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-DEMO", "-DEMO_ACCESSO", scenario, "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
    }

    private func elemento(_ testo: String, contiene: Bool = false) -> XCUIElement {
        let predicato = NSPredicate(format: contiene ? "label CONTAINS[c] %@" : "label ==[c] %@", testo)
        return app.descendants(matching: .any).matching(predicato).firstMatch
    }

    private func attendi(_ testo: String, contiene: Bool = false, secondi: TimeInterval = 30, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(elemento(testo, contiene: contiene).waitForExistence(timeout: secondi), "non compare «\(testo)»", file: file, line: line)
    }

    func testAccessoConNomePasswordEPassaggioTraLeSchede() {
        avvia("accedi")
        let nome = app.textFields["Nome utente"]
        XCTAssertTrue(nome.waitForExistence(timeout: 30), "la schermata di accesso deve comparire")
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists, "senza accesso non si vede l'app")
        let entra = app.buttons["Entra"]
        XCTAssertTrue(entra.exists)
        XCTAssertFalse(entra.isEnabled, "con i campi vuoti non si può entrare")

        // Registrati: compare il codice d'invito
        app.buttons["Registrati"].tap()
        attendi("Codice d'invito", contiene: true)
        XCTAssertTrue(app.buttons["Crea l'account"].exists)
        // Recupera: compare il codice di recupero
        app.buttons["Recupera"].tap()
        XCTAssertTrue(app.textFields["Codice di recupero"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Cambia la password"].exists)

        // di nuovo Accedi, con nome e password: si entra
        app.buttons["Accedi"].tap()
        nome.tap()
        nome.typeText("mister.rossi")
        let password = app.secureTextFields["Password"]
        password.tap()
        password.typeText("Tre-Quarti-Dieci")
        XCTAssertTrue(entra.isEnabled)
        entra.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30), "dopo l'accesso compare l'app")
    }

    func testCodiceDiRecuperoSiVedeEsiConfermaPrimaDiProseguire() {
        avvia("codice")
        attendi("Salva il tuo codice di recupero")
        attendi("K 7 M 2 P", contiene: true)   // per VoiceOver il codice si legge lettera per lettera
        let continua = app.buttons["Continua"]
        XCTAssertTrue(continua.waitForExistence(timeout: 10))
        XCTAssertFalse(continua.isEnabled, "senza la conferma «l'ho salvato» non si va avanti")
        XCTAssertTrue(app.buttons["Copia"].exists)
        let conferma = app.switches.firstMatch
        XCTAssertTrue(conferma.waitForExistence(timeout: 10))
        // Il tocco sull'interruttore a volte non arriva al primo colpo nel simulatore: si tocca la levetta (a destra) e si
        // riprova finché il pulsante si accende (al massimo tre volte, sempre con attesa).
        var acceso = false
        for _ in 0..<3 where !acceso {
            if (conferma.value as? String) != "1" { conferma.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap() }
            acceso = XCTWaiter().wait(for: [expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: continua)], timeout: 5) == .completed
        }
        XCTAssertTrue(acceso, "dopo la conferma il pulsante Continua si accende")
        continua.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 30))
    }

    func testSezioneIlTuoAccountInLega() {
        avvia("account")
        attendi("Il tuo account")
        attendi("mister.rossi")
        attendi("Cambia password")
        attendi("Nuovo codice di recupero")
        attendi("Elimina l'account")
        XCTAssertTrue(app.buttons["Esci"].exists)
    }

    func testRetAssenteDiceCosaFare() {
        avvia("rete")
        attendi("Non riesco a raggiungere il server", contiene: true)
        XCTAssertTrue(app.buttons["Entra"].waitForExistence(timeout: 10), "si può riprovare")
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    func testTroppiTentativiMostraIlContoAllaRovescia() {
        avvia("limite")
        attendi("Troppi tentativi", contiene: true)
        let conto = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Riprova tra'")).firstMatch
        XCTAssertTrue(conto.waitForExistence(timeout: 10))
        XCTAssertFalse(conto.isEnabled, "durante l'attesa non si riprova")
    }

    func testServerCheNonESchieraxi() {
        avvia("non-valido")
        attendi("non sembra un server di SchieraXI", contiene: true)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
    }

    func testCambioRapidoTraLeSchedeNonRompeNiente() {
        avvia("accedi")
        XCTAssertTrue(app.textFields["Nome utente"].waitForExistence(timeout: 30))
        for _ in 0..<6 {
            app.buttons["Registrati"].tap()
            app.buttons["Recupera"].tap()
            app.buttons["Accedi"].tap()
        }
        // Con i tocchi a raffica sul Mac di GitHub un tocco può perdersi: si rimette «Accedi» finché il pulsante «Entra» compare.
        var tornata = false
        for _ in 0..<6 where !tornata {
            if app.buttons["Entra"].waitForExistence(timeout: 8) { tornata = true; break }
            app.buttons["Accedi"].tap()
        }
        XCTAssertTrue(tornata, "dopo i cambi rapidi la scheda Accedi deve tornare")
        XCTAssertTrue(app.secureTextFields["Password"].waitForExistence(timeout: 20))
    }

    func testInSecondoPianoLaPasswordScrittaSiCancella() {
        avvia("accedi")
        let password = app.secureTextFields["Password"]
        XCTAssertTrue(password.waitForExistence(timeout: 30))
        password.tap()
        password.typeText("Tre-Quarti-Dieci")
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()
        XCTAssertTrue(password.waitForExistence(timeout: 10))
        XCTAssertFalse((password.value as? String ?? "").contains("•"), "tornando nell'app la password non c'è più")
    }

    func testLegaSenzaRoseSpiegaCosaFare() {
        avvia("rose")
        attendi("Manca la tua squadra")
        XCTAssertTrue(app.buttons["Importa le rose"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Apri la web app nel browser"].exists)
    }
}
