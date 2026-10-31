import XCTest
@testable import Schieraxi

/// Scadenza della formazione e numerazione della lega: tutti i campi nuovi del server sono facoltativi.
final class TempiLegaTests: XCTestCase {
    private func oggi(_ extra: String) throws -> Oggi {
        try Decodifica.decodifica(Data("{\"giornata\": 10, \"inizio\": \"2026-11-08 18:30\"\(extra)}".utf8))
    }

    func testIlContoPuntaAllaScadenza() throws {
        let o = try oggi(", \"scadenza\": \"2026-11-08 18:00\", \"minuti_scadenza\": 30")
        XCTAssertEqual(o.chiusura, "2026-11-08 18:00")
        XCTAssertEqual(o.minutiScadenza, 30)
    }

    func testServerVecchioOScadenzaVuotaUsaLInizio() throws {
        XCTAssertEqual(try oggi("").chiusura, "2026-11-08 18:30")
        XCTAssertEqual(try oggi(", \"scadenza\": null").chiusura, "2026-11-08 18:30")
        XCTAssertEqual(try oggi(", \"scadenza\": \"  \"").chiusura, "2026-11-08 18:30")
    }

    func testEtichettaDellaGiornata() throws {
        XCTAssertEqual(try oggi("").etichettaGiornata, "Giornata 10")
        XCTAssertEqual(try oggi(", \"giornata_lega\": null").etichettaGiornata, "Giornata 10")
        XCTAssertEqual(try oggi(", \"giornata_lega\": 10").etichettaGiornata, "Giornata 10")
        XCTAssertEqual(try oggi(", \"giornata_lega\": 7").etichettaGiornata, "Giornata 7 di lega (Serie A 10)")
        XCTAssertEqual(try oggi(", \"giornata_lega\": 7").giornataMostrata, 7)
        XCTAssertEqual(try oggi(", \"giornata_lega\": 0").giornataMostrata, 10)
    }

    func testIlRiassuntoDelWidgetUsaLaScadenza() throws {
        let o = try oggi(", \"scadenza\": \"2026-11-08 18:00\"")
        XCTAssertEqual(RiassuntoOggi(oggi: o).inizio, Quando.data("2026-11-08 18:00"))
    }

    func testFrasiDiSpiegazione() {
        XCTAssertEqual(TempiLega.spiegaScadenza(0), "La formazione si chiude all'inizio della prima partita.")
        XCTAssertEqual(TempiLega.spiegaScadenza(1), "La formazione si chiude 1 minuto prima della prima partita.")
        XCTAssertEqual(TempiLega.spiegaScadenza(45), "La formazione si chiude 45 minuti prima della prima partita.")
        XCTAssertTrue(TempiLega.spiegaPartenza(1).contains("coincidono"))
        XCTAssertTrue(TempiLega.spiegaPartenza(4).contains("la 4ª di Serie A"))
        XCTAssertTrue(TempiLega.spiegaPartenza(99).contains("la 38ª"))
    }

    func testLeRegoleConservanoITempiNelSalvataggio() throws {
        var regole = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"nome_lega":"Lega","moduli":["3-4-3"]}"#.utf8))
        // server vecchio: i campi mancano e non cambia nulla finché non si tocca
        XCTAssertNil(regole.valore("scadenza_minuti"))
        regole.imposta("scadenza_minuti", JSONValue.numero(30))
        regole.imposta("prima_giornata_lega", JSONValue.numero(4))
        let pronte = try RegoleLogica.preparaPerSalvataggio(regole)
        XCTAssertEqual(pronte.valore("scadenza_minuti"), .intero(30))
        XCTAssertEqual(pronte.valore("prima_giornata_lega"), .intero(4))
    }
}
