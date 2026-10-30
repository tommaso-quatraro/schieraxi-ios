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

/// Il codice di collegamento del widget e la diagnostica della condivisione.
final class CodiceWidgetTests: XCTestCase {
    func testIlCodiceFaIlGiroCompleto() {
        let codice = CodiceWidget.crea(indirizzo: "https://uno.invalid:8443", token: "tok_abc-123")
        XCTAssertTrue(codice.hasPrefix("schieraxi1."))
        XCTAssertFalse(codice.contains("="), "senza il riempimento: si copia e si incolla meglio")
        XCTAssertFalse(codice.contains("+") || codice.contains("/"))
        let c = CodiceWidget.leggi(codice)
        XCTAssertEqual(c, CodiceWidget.Contenuto(i: "https://uno.invalid:8443", t: "tok_abc-123"))
    }

    func testSenzaTokenSoloIndirizzo() {
        let c = CodiceWidget.leggi(CodiceWidget.crea(indirizzo: "https://uno.invalid", token: nil))
        XCTAssertEqual(c?.i, "https://uno.invalid")
        XCTAssertNil(c?.t)
        XCTAssertNil(CodiceWidget.leggi(CodiceWidget.crea(indirizzo: "https://uno.invalid", token: ""))?.t)
    }

    func testSpaziEACapoIntornoSiIgnorano() {
        let codice = CodiceWidget.crea(indirizzo: "https://uno.invalid", token: "t")
        XCTAssertNotNil(CodiceWidget.leggi("  \n" + codice + "\n "))
    }

    func testUnIndirizzoSempliceVaBene() {
        XCTAssertEqual(CodiceWidget.leggi("https://uno.invalid")?.i, "https://uno.invalid")
    }

    func testCodiciSbagliatiONemiciNonRompono() {
        for cattivo in ["", "ciao", "schieraxi1.", "schieraxi1.!!!", "schieraxi1.e30", String(repeating: "a", count: 5000), "schieraxi1." + String(repeating: "A", count: 100)] {
            XCTAssertNil(CodiceWidget.leggi(cattivo), cattivo)
        }
    }

    func testLaDiagnosticaDiceCosaManca() {
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("diag-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        Condiviso.cartellaDiProva = cartella
        defer { Condiviso.cartellaDiProva = nil; try? FileManager.default.removeItem(at: cartella) }
        var d = Condiviso.diagnostica(info: ["ALTAppGroups": ["group.it.tommaso.schieraxi.XYZ"]])
        XCTAssertEqual(d.scrittiDaSideStore, ["group.it.tommaso.schieraxi.XYZ"])
        XCTAssertEqual(d.provati.first, "group.it.tommaso.schieraxi.XYZ")
        XCTAssertFalse(d.filePresente)
        XCTAssertFalse(d.haIndirizzo)
        XCTAssertTrue(d.breve.contains("file no"), d.breve)
        Condiviso.sincronizza(indirizzo: "https://uno.invalid", token: "tok")
        d = Condiviso.diagnostica(info: [:])
        XCTAssertTrue(d.filePresente)
        XCTAssertTrue(d.haIndirizzo)
        XCTAssertTrue(d.haToken)
        XCTAssertNotNil(d.ultimaScrittura)
        XCTAssertTrue(d.breve.contains("token sì"), d.breve)
        XCTAssertTrue(d.lungo.contains("Gruppi provati"))
    }
}

/// Il riassunto per il widget «Da controllare».
final class DubbiWidgetTests: XCTestCase {
    func testDalleAvvisiDiOggiVengonoIDubbiDellaFormazione() throws {
        let corpo = #"""
        {"giornata": 11, "inizio": "2026-10-31 18:30", "con_probabili": false,
         "formazione": {"modulo": "3-4-3", "punteggio_atteso": 73.7},
         "avvisi": [
           {"id": 5, "nome": "Giocatore 044", "ruolo": "A", "squadra": "inter", "tipo": "dubbio", "in_formazione": true, "p_voto": 0.55},
           {"id": 6, "nome": "Giocatore 004", "ruolo": "D", "tipo": "diffidato", "in_formazione": true},
           {"id": 7, "nome": "Riserva", "ruolo": "C", "tipo": "infortunato", "in_formazione": false}
         ]}
        """#
        let oggi: Oggi = try Decodifica.decodifica(Data(corpo.utf8))
        let r = RiassuntoOggi(oggi: oggi)
        XCTAssertEqual(r.daControllare, 2)
        XCTAssertEqual(r.dubbi?.map(\.id), [5, 6])
        XCTAssertEqual(r.dubbi?.first?.descrizione, "Dubbio 55%")
        XCTAssertEqual(r.dubbi?.last?.descrizione, "Diffidato")
    }

    func testAlMassimoSeiDubbi() throws {
        let avvisi = (1...9).map { #"{"id": \#($0), "nome": "G\#($0)", "tipo": "dubbio", "in_formazione": true}"# }.joined(separator: ",")
        let corpo = #"{"giornata": 1, "avvisi": [\#(avvisi)]}"#
        let oggi: Oggi = try Decodifica.decodifica(Data(corpo.utf8))
        let r = RiassuntoOggi(oggi: oggi)
        XCTAssertEqual(r.daControllare, 9)
        XCTAssertEqual(r.dubbi?.count, 6)
    }

    func testUnRiassuntoVecchioSenzaDubbiSiLegge() throws {
        let vecchio = #"{"giornata": 9, "daControllare": 2, "scaricatoIl": 783000000}"#
        let r = try JSONDecoder().decode(RiassuntoOggi.self, from: Data(vecchio.utf8))
        XCTAssertNil(r.dubbi)
        XCTAssertEqual(r.daControllare, 2)
    }

    func testDescrizioneSenzaTipo() {
        XCTAssertEqual(DubbioRiassunto(id: 1, nome: "A", ruolo: nil, tipo: nil, pVoto: nil).descrizione, "Da controllare")
    }
}
