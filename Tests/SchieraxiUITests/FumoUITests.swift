import XCTest

/// Test di fumo dell'interfaccia: l'app parte in modalità demo (dati finti, senza rete) e le cinque sezioni si raggiungono.
final class FumoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-DEMO", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
    }

    func testLeCinqueSezioniSonoRaggiungibili() {
        let barra = app.tabBars.firstMatch
        XCTAssertTrue(barra.waitForExistence(timeout: 30), "la barra delle sezioni deve comparire")
        for nome in ["Oggi", "Formazione", "Mercato", "Scambi", "Lega"] {
            XCTAssertTrue(barra.buttons[nome].exists, "manca la sezione \(nome)")
        }
    }
}
