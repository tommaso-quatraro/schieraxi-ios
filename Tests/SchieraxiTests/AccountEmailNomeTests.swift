import XCTest
@testable import Schieraxi

// Maiuscole del nome ed email dell'account: controlli leggeri sul telefono e lettura tollerante della risposta di `/api/account/me`.
// Solo indirizzi finti (example.invalid).

final class AccountEmailNomeTests: XCTestCase {
    func testMaiuscoleDelNome() {
        XCTAssertNil(RegoleAccount.problemaMaiuscole("TuttoBene", nomeUtente: "tuttobene"))
        XCTAssertNil(RegoleAccount.problemaMaiuscole("  Mister.Rossi ", nomeUtente: "mister.rossi"))
        XCTAssertNotNil(RegoleAccount.problemaMaiuscole("", nomeUtente: "mister"))
        XCTAssertNotNil(RegoleAccount.problemaMaiuscole("Mistero", nomeUtente: "mister"), "le lettere devono restare le stesse")
    }

    func testControlloEmail() {
        XCTAssertNil(RegoleAccount.problemaEmail("nome@example.invalid"))
        XCTAssertNotNil(RegoleAccount.problemaEmail(""))
        XCTAssertNotNil(RegoleAccount.problemaEmail("senza-chiocciola"))
        XCTAssertNotNil(RegoleAccount.problemaEmail("a@b"))
        XCTAssertNotNil(RegoleAccount.problemaEmail("a b@example.invalid"))
        XCTAssertNotNil(RegoleAccount.problemaEmail("@example.invalid"))
    }

    func testLaRispostaLeggeEmailEInAttesaConTolleranza() throws {
        let utente = #""utente": {"id": 1, "nome_utente": "mister", "ruolo": "utente", "nome_visualizzato": "Mister"}"#
        func leggi(_ extra: String) throws -> RispostaAccount {
            try Decodifica.decodifica(Data("{\"multiutente\": true, \(utente)\(extra)}".utf8))
        }
        let ok = try leggi(#", "email": "nome@example.invalid", "email_in_attesa": null"#)
        XCTAssertEqual(ok.email, "nome@example.invalid")
        XCTAssertNil(ok.emailInAttesa)
        let attesa = try leggi(#", "email_in_attesa": "altro@example.invalid""#)
        XCTAssertNil(attesa.email)
        XCTAssertEqual(attesa.emailInAttesa, "altro@example.invalid")
        // server vecchio o campo di tipo strano: niente email, ma la risposta si legge lo stesso
        XCTAssertNil(try leggi("").email)
        XCTAssertNil(try leggi(#", "email": 42"#).email)
        XCTAssertEqual(try leggi("").utente?.nome, "Mister")
    }
}
