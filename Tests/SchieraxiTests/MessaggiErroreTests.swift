import XCTest
@testable import Schieraxi

/// Messaggi d'errore per chi usa l'app: semplici, senza codici e senza «server acceso»; il «Riprova» resta dove serve.
final class MessaggiErroreTests: XCTestCase {
    func testNienteParoleTecniche() {
        let testi = [ErroreApi.rete("x"), .timeout, .risposta(500), .risposta(502), .risposta(401), .risposta(403), .server("Nessuna rosa importata")]
            .compactMap(\.errorDescription)
        for t in testi {
            XCTAssertFalse(t.contains("codice"), t)
            XCTAssertFalse(t.contains("acceso"), t)
            XCTAssertFalse(t.hasPrefix("Il server dice"), t)
        }
        XCTAssertEqual(ErroreApi.server("Nessuna rosa importata").errorDescription, "Nessuna rosa importata")
    }

    func testUnSoloMessaggioPerLaReteAssente() {
        XCTAssertEqual(ErroreApi.rete("spenta").errorDescription, ErroreApi.testoNonRaggiungibile)
        XCTAssertEqual(DatiPersonali.testoErrore(ErroreApi.rete("x")), ErroreApi.testoNonRaggiungibile)
        XCTAssertEqual(SchermataAccesso.testoErrore(ErroreApi.rete("x")), ErroreApi.testoNonRaggiungibile)
    }

    func testRiprovaTraPocoNonEUnLimite() {
        XCTAssertFalse(ErroreVista.eLimite(ErroreApi.timeout.errorDescription ?? ""))
        XCTAssertFalse(ErroreVista.eLimite(ErroreApi.risposta(500).errorDescription ?? ""))
        XCTAssertFalse(ErroreVista.eLimite(ErroreApi.rete("x").errorDescription ?? ""))
        XCTAssertTrue(ErroreVista.eLimite(ErroreApi.troppiTentativi("Troppe ricerche oggi.", riprovaTra: 45).errorDescription ?? ""))
        XCTAssertTrue(ErroreVista.eLimite("Hai finito le ricerche di oggi. Riprova domani."))
    }
}
