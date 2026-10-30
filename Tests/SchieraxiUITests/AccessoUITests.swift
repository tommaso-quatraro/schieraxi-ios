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
        conferma.tap()
        // lo stato di SwiftUI si aggiorna un attimo dopo il tocco: si aspetta che il pulsante si accenda
        let acceso = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: continua)
        wait(for: [acceso], timeout: 15)
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

    func testLegaSenzaRoseSpiegaCosaFare() {
        avvia("rose")
        attendi("Manca la tua squadra")
        XCTAssertTrue(app.buttons["Importa le rose"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Apri la web app nel browser"].exists)
    }
}
