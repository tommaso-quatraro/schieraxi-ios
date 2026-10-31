import XCTest
@testable import Schieraxi

/// Quali voci di menu e quali «Da fare» vede un utente normale.
final class FunzioniLegaTests: XCTestCase {
    private func oggi(_ daFare: String) throws -> Oggi {
        try Decodifica.decodifica(Data(#"{"giornata": 11, "inizio": "2026-10-31 18:30", "da_fare": \#(daFare)}"#.utf8))
    }

    func testIlCalendarioSiVedeSoloSeNominatoOConMostraTutte() {
        XCTAssertFalse(StatoFunzioni.tutteAccese.vedeCalendario, "una chiave che manca vale spenta")
        XCTAssertFalse(StatoFunzioni(scelte: ["elenco_giocatori": true]).vedeCalendario, "non dipende più dall'elenco dei giocatori")
        XCTAssertTrue(StatoFunzioni(scelte: ["calendario": true]).vedeCalendario)
        XCTAssertTrue(StatoFunzioni(scelte: [:], mostraTutte: true).vedeCalendario)
    }

    func testLeImmaginiWebConMostraTutteRestanoSpenteSeIlServerLeBlocca() {
        let bloccate = StatoFunzioni(scelte: ["immagini_web": false], mostraTutte: true)
        XCTAssertTrue(bloccate.acceso(Funzione.immaginiWeb), "per i menu «Mostra tutte» apre tutto")
        XCTAssertFalse(bloccate.accesoDavvero(Funzione.immaginiWeb), "ma il server le blocca: il pulsante non si vede")
        XCTAssertTrue(StatoFunzioni.tutteAccese.accesoDavvero(Funzione.immaginiWeb), "server vecchio: come prima")
    }

    func testUtenteNormaleNonVedeLeVociTecniche() throws {
        let o = try oggi(#"""
        [{"id": "1", "tipo": "dubbio", "testo": "Dubbio"}, {"id": "2", "tipo": "certificato", "testo": "Certificato"},
         {"id": "3", "tipo": "server", "testo": "Server"}, {"id": "4", "tipo": "backup", "testo": "Backup"},
         {"id": "5", "tipo": "rose", "testo": "Rose"}]
        """#)
        XCTAssertEqual(o.cose(funzioni: .tutteAccese, tecniche: false).map(\.id), ["1", "5"])
        XCTAssertEqual(o.cose(funzioni: .tutteAccese, tecniche: true).map(\.id), ["1", "2", "3", "4", "5"])
    }

    func testLeCoseDiUnaFunzioneSpentaNonSiVedono() throws {
        let o = try oggi(#"""
        [{"id": "1", "tipo": "diario", "testo": "Diario"}, {"id": "2", "tipo": "scambio", "testo": "Scambio"},
         {"id": "3", "tipo": "backup", "testo": "Backup"}, {"id": "4", "tipo": "formazione", "testo": "Formazione"}]
        """#)
        let spente = StatoFunzioni(scelte: ["diario": false, "scambi_trova": false, "backup": false])
        XCTAssertEqual(o.cose(funzioni: spente, tecniche: true).map(\.id), ["4"])
    }
}
