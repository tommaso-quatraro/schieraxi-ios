import XCTest
@testable import Schieraxi

/// «Sotto il cofano»: lettura tollerante, filtro Base/Nerd/Tutto, numeri (attuali poi di riferimento), glossario, rimandi.
final class SottoIlCofanoTests: XCTestCase {
    private func leggi(_ json: String) throws -> SottoIlCofano {
        // come l'app: SENZA conversione dei nomi (le chiavi dei numeri contengono underscore)
        try Decodifica.decodifica(Data(json.utf8), snake: false)
    }

    private let completo = """
    {"formato": 1, "titolo": "Sotto il cofano", "sottotitolo": "Come ragiona SchieraXI", "aggiornato": "2026-10-30",
     "livelli": {"base": "Semplice", "nerd": "Tecnico"}, "introduzione": ["Uno", "Due"], "campo_nuovo": {"x": 1},
     "sezioni": [
       {"id": "a", "titolo": "Prima", "livello": "base", "paragrafi": ["p1"], "numeri": ["app.errore_modello", "backtest.errore_modello", "non.esiste"],
        "esempio": {"titolo": "T", "testo": "X", "origine": "vero"},
        "rimandi": [{"schermata": "formazione", "etichetta": "Formazione"}, {"schermata": "giocatore", "etichetta": "Scheda"}, {"schermata": "boh", "etichetta": "Nuova"}]},
       {"id": "b", "titolo": "Seconda", "livello": "nerd", "formula": "a = b\\nc = d"},
       {"titolo": "Senza id", "livello": "livello_nuovo"},
       {"id": "rotta", "paragrafi": 5},
       7
     ],
     "glossario": [{"termine": "Fantavoto", "spiegazione": "Il voto con i bonus"}, {"termine": "È importante", "spiegazione": "Perché sì"}, {"spiegazione": "senza termine"}, "x"],
     "misure": {"riferimento": {"data": "2026-10-29", "voci": {"backtest.errore_modello": {"valore": 1.46, "etichetta": "Errore del modello", "unita": "punti"},
                                                            "app.errore_modello": {"valore": 1.5, "etichetta": "Errore recente", "unita": "punti"},
                                                            "storta": "boh"}},
                "attuali": {"voci": {"app.errore_modello": {"valore": 1.6, "aggiornato": "2026-10-28T00:38:07"}}}}}
    """

    func testLeggeTuttoESaltaLeVociSbagliate() throws {
        let c = try leggi(completo)
        XCTAssertEqual(c.titolo, "Sotto il cofano")
        XCTAssertEqual(c.introduzione, ["Uno", "Due"])
        XCTAssertEqual(c.sezioni.map(\.id), ["a", "b", "Senza id"], "la sezione 'rotta' (senza titolo) e il numero 7 si saltano; una senza id usa il titolo")
        XCTAssertEqual(c.glossario.map(\.termine).sorted(), ["Fantavoto", "È importante"], "il termine senza nome e il testo semplice si saltano")
        XCTAssertFalse(c.piuNuovaDellApp)
    }

    func testRispostaVuotaOStranaNonRompe() throws {
        let vuota = try leggi("{}")
        XCTAssertTrue(vuota.sezioni.isEmpty)
        XCTAssertNil(vuota.rigaDate)
        XCTAssertTrue(try leggi("[1, 2]").sezioni.isEmpty, "anche una forma inattesa dà una pagina vuota, non un errore")
    }

    func testFormatoPiuNuovoSiDice() throws {
        XCTAssertTrue(try leggi(#"{"formato": 2}"#).piuNuovaDellApp)
        XCTAssertFalse(try leggi("{}").piuNuovaDellApp)
    }

    func testFiltroBaseNerdTutto() throws {
        let c = try leggi(completo)
        XCTAssertEqual(c.sezioniVisibili(.base).map(\.id), ["a", "Senza id"], "un livello sconosciuto conta come base")
        XCTAssertEqual(c.sezioniVisibili(.nerd).map(\.id), ["b"])
        XCTAssertEqual(c.sezioniVisibili(.tutto).count, 3)
        XCTAssertEqual(LivelloCofano(ricordato: "nerd"), .nerd)
        XCTAssertEqual(LivelloCofano(ricordato: "qualcosa"), .base, "un valore ricordato sconosciuto torna a base")
    }

    func testNumeriPrimaGliAttualiPoiQuelliDiRiferimento() throws {
        let c = try leggi(completo)
        let numeri = c.numeri(di: try XCTUnwrap(c.sezioni.first))
        XCTAssertEqual(numeri.map(\.chiave), ["app.errore_modello", "backtest.errore_modello"], "il numero che non esiste da nessuna parte non c'è")
        XCTAssertEqual(numeri[0].valore, "1,60 punti")
        XCTAssertTrue(numeri[0].attuale)
        XCTAssertEqual(numeri[0].etichetta, "Errore recente", "l'etichetta viene dal riferimento")
        XCTAssertEqual(numeri[0].nota, "misurato il 28 ott 2026")
        XCTAssertEqual(numeri[1].valore, "1,46 punti")
        XCTAssertFalse(numeri[1].attuale)
        XCTAssertEqual(numeri[1].nota, "misurato il 29 ott 2026")
    }

    func testFormatoDeiValori() {
        XCTAssertEqual(SottoIlCofano.formattaValore(80, unita: "%"), "80%")
        XCTAssertEqual(SottoIlCofano.formattaValore(8, unita: "giornate"), "8 giornate")
        XCTAssertEqual(SottoIlCofano.formattaValore(0.456, unita: nil), "0,46")
        XCTAssertEqual(SottoIlCofano.formattaValore(.nan, unita: "punti"), "—")
        XCTAssertEqual(SottoIlCofano.nomeDaChiave("backtest.errore_modello"), "errore modello")
    }

    func testRigaDate() throws {
        XCTAssertEqual(try leggi(completo).rigaDate, "Testi aggiornati il 30 ott 2026; misure del 29 ott 2026")
        XCTAssertEqual(try leggi(#"{"aggiornato": "2026-10-30"}"#).rigaDate, "Testi aggiornati il 30 ott 2026")
    }

    func testGlossarioCercabileSenzaBadareAAccentiEMaiuscole() throws {
        let c = try leggi(completo)
        XCTAssertEqual(c.glossario(cercando: "").map(\.termine), ["È importante", "Fantavoto"], "in ordine alfabetico italiano")
        XCTAssertEqual(c.glossario(cercando: "IMPORTANTE").map(\.termine), ["È importante"])
        XCTAssertEqual(c.glossario(cercando: "e importante").map(\.termine), ["È importante"], "senza accento")
        XCTAssertEqual(c.glossario(cercando: "bonus").map(\.termine), ["Fantavoto"], "cerca anche nella spiegazione")
        XCTAssertTrue(c.glossario(cercando: "zzz").isEmpty)
    }

    func testEtichettaDellEsempio() throws {
        XCTAssertEqual(EsempioCofano(origine: "vero").etichetta, "Numeri veri")
        XCTAssertEqual(EsempioCofano(origine: "di calcolo").etichetta, "Esempio di calcolo")
        XCTAssertEqual(EsempioCofano(origine: nil).etichetta, "Esempio di calcolo")
    }

    func testRimandiConosciutiEDSconosciuti() {
        XCTAssertEqual(DestinazioneCofano.da("formazione"), .sezione(.formazione))
        XCTAssertEqual(DestinazioneCofano.da("regole"), .lega(.regole))
        XCTAssertEqual(DestinazioneCofano.da("stato-dati"), .lega(.stato))
        XCTAssertEqual(DestinazioneCofano.da("novita"), .impostazioni(.novita))
        XCTAssertNil(DestinazioneCofano.da("giocatore"), "serve un codice: resta testo")
        XCTAssertNil(DestinazioneCofano.da("una-nuova"))
        XCTAssertNil(DestinazioneCofano.da(nil))
    }

    @MainActor
    func testSenzaReteRestaLUltimaCopia() async throws {
        let indirizzo = "https://prova-cofano-\(UUID().uuidString).invalid"
        let corpo = Data(completo.utf8)
        let funziona = ServerDiProva(indirizzo: indirizzo) { _, _, _ in corpo }
        let c1 = Caricatore<SottoIlCofano>("/api/sotto-il-cofano", snake: false, server: funziona)
        await c1.ricarica()
        XCTAssertEqual(c1.dato?.sezioni.count, 3)
        // il salvataggio su disco è in coda: si aspetta che arrivi
        for _ in 0..<50 {
            if await Cache.leggi("/api/sotto-il-cofano", indirizzo: indirizzo) != nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        // il server risponde 503: si vede la copia salvata, con l'avviso «dati salvati»
        let guasto = ServerDiProva(indirizzo: indirizzo) { _, _, _ in throw ErroreApi.server("I testi non sono disponibili in questo momento") }
        let c2 = Caricatore<SottoIlCofano>("/api/sotto-il-cofano", snake: false, server: guasto)
        await c2.ricarica()
        XCTAssertEqual(c2.dato?.sezioni.count, 3, "l'ultima copia salvata")
        XCTAssertNotNil(c2.datiSalvati)
    }
}
