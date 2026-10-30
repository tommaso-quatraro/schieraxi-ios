import XCTest
@testable import Schieraxi

/// Dati condivisi tra app e widget (App Group): indirizzo, token e ultimo riassunto in un file del contenitore condiviso.
final class CondivisoTests: XCTestCase {
    private var cartella: URL!

    override func setUp() {
        super.setUp()
        cartella = FileManager.default.temporaryDirectory.appendingPathComponent("condiviso-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        Condiviso.cartellaDiProva = cartella
    }

    override func tearDown() {
        Condiviso.cartellaDiProva = nil
        try? FileManager.default.removeItem(at: cartella)
        super.tearDown()
    }

    func testIdentificativiDaSideStore() {
        // SideStore riscrive il gruppo con un suffisso e lo mette in Info.plist (ALTAppGroups): si prova prima quello
        let info: [String: Any] = ["ALTAppGroups": ["group.it.tommaso.schieraxi.ABCDE12345", "group.altro.invalid", "group.it.tommaso.schieraxi.ABCDE12345"]]
        XCTAssertEqual(Condiviso.identificativi(info: info), ["group.it.tommaso.schieraxi.ABCDE12345", "group.it.tommaso.schieraxi"])
        XCTAssertEqual(Condiviso.identificativi(info: [:]), ["group.it.tommaso.schieraxi"])
        XCTAssertEqual(Condiviso.identificativi(info: ["ALTAppGroups": "non una lista"]), ["group.it.tommaso.schieraxi"])
        XCTAssertEqual(Condiviso.identificativi(info: nil), ["group.it.tommaso.schieraxi"])
    }

    func testIndirizzoETokenSiScambiano() {
        XCTAssertNil(Condiviso.leggi().indirizzo)
        Condiviso.sincronizza(indirizzo: "https://uno.invalid", token: "abc123")
        let d = Condiviso.leggi()
        XCTAssertEqual(d.indirizzo, "https://uno.invalid")
        XCTAssertEqual(d.token(per: "https://uno.invalid"), "abc123")
        XCTAssertNil(d.token(per: "https://due.invalid"), "il token non va a un altro indirizzo")
    }

    func testCambiandoServerIlVecchioTokenSiTogliePoi() {
        Condiviso.sincronizza(indirizzo: "https://uno.invalid", token: "abc123")
        Condiviso.sincronizza(indirizzo: "https://due.invalid", token: nil)
        let d = Condiviso.leggi()
        XCTAssertEqual(d.indirizzo, "https://due.invalid")
        XCTAssertNil(d.token, "il token del server di prima non resta")
        XCTAssertNil(d.token(per: "https://due.invalid"))
    }

    func testDimenticaTogliTokenERiassunto() {
        Condiviso.sincronizza(indirizzo: "https://uno.invalid", token: "abc123")
        Condiviso.salvaRiassunto(RiassuntoOggi(giornata: 11, inizio: nil, modulo: "3-4-3", punti: 64.5, daControllare: 1, probabili: true, scaricatoIl: Date()))
        XCTAssertNotNil(Condiviso.leggi().riassunto)
        Condiviso.dimentica()
        let d = Condiviso.leggi()
        XCTAssertNil(d.token)
        XCTAssertNil(d.riassunto)
        XCTAssertEqual(d.indirizzo, "https://uno.invalid", "l'indirizzo è del telefono, non di un utente")
    }

    func testLArchivioSpecchiatoCopiaIlToken() {
        let base = MemoriaToken()
        let archivio = ArchivioSpecchiato(base: base)
        archivio.salva("tok-1", server: "https://uno.invalid")
        XCTAssertEqual(base.leggi(server: "https://uno.invalid"), "tok-1")
        XCTAssertEqual(Condiviso.leggi().token(per: "https://uno.invalid"), "tok-1")
        Condiviso.salvaRiassunto(RiassuntoOggi(giornata: 1, inizio: nil, modulo: nil, punti: nil, daControllare: 0, probabili: nil, scaricatoIl: Date()))
        archivio.cancella(server: "https://altro.invalid")
        XCTAssertNotNil(Condiviso.leggi().token, "togliere il token di un altro server non tocca questo")
        archivio.cancella(server: "https://uno.invalid")
        XCTAssertNil(base.leggi(server: "https://uno.invalid"))
        XCTAssertNil(Condiviso.leggi().token)
        XCTAssertNil(Condiviso.leggi().riassunto)
    }

    func testIlRiassuntoVieneDaOggi() throws {
        let oggi: Oggi = try Decodifica.decodifica(try Fixture.dati("oggi"))
        let r = RiassuntoOggi(oggi: oggi)
        XCTAssertEqual(r.giornata, oggi.giornata)
        XCTAssertEqual(r.modulo, oggi.formazione?.modulo)
        Condiviso.salvaRiassunto(r)
        XCTAssertEqual(Condiviso.leggi().riassunto?.giornata, oggi.giornata)
    }

    func testSenzaGruppoNonSuccedeNiente() {
        Condiviso.cartellaDiProva = nil
        // nel simulatore il gruppo può esistere o no: l'importante è che nessuna chiamata si rompa
        _ = Condiviso.disponibile
        _ = Condiviso.leggi()
        Condiviso.sincronizza(indirizzo: "https://x.invalid", token: nil)
        Condiviso.dimentica()
    }

    func testUnFileRovinatoSiIgnora() throws {
        try Data("non json".utf8).write(to: cartella.appendingPathComponent("condiviso.json"))
        XCTAssertEqual(Condiviso.leggi(), DatiCondivisi())
        Condiviso.sincronizza(indirizzo: "https://uno.invalid", token: nil)
        XCTAssertEqual(Condiviso.leggi().indirizzo, "https://uno.invalid", "si riscrive pulito")
    }
}
