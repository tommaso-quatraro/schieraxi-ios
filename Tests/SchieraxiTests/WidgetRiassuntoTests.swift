import XCTest
@testable import Schieraxi

/// Il riassunto compatto dei widget (`GET /api/widget`): lettura, scelta di chi gioca, scarico con ETag e copia.
final class WidgetRiassuntoTests: XCTestCase {
    static let corpo = #"""
    {"giornata": 11, "prima_partita": "2026-10-31 18:30", "scadenza": "2026-10-31 18:30", "ore_mancanti": 5.5, "iniziata": false, "con_probabili": true,
     "squadra": "Schiera FC", "crediti_residui": 12,
     "formazione": {"modulo": "3-4-3", "punti_attesi": 73.7,
       "titolari": [{"id": 1, "nome": "Giocatore 096", "ruolo": "P", "punti_attesi": 6.1, "p_voto": 0.98, "avatar": {"p": 2, "b": 1}},
                    {"id": 2, "nome": "Giocatore 002", "ruolo": "D", "punti_attesi": 6.4, "p_voto": 0.96}],
       "panchina": [10, 11, 12]},
     "avvisi": [{"id": 5, "nome": "Giocatore 044", "ruolo": "A", "tipo": "dubbio", "in_formazione": true, "p_voto": 0.55},
                {"id": 7, "nome": "Riserva", "ruolo": "C", "tipo": "infortunato", "in_formazione": false}],
     "rosa": [{"id": 1, "nome": "Giocatore 096", "ruolo": "P", "avversario": "roma", "in_casa": true, "data_partita": "2026-10-31 20:45", "stato": "disponibile", "percentuale": 98, "dubbio": false, "diffidato": false, "titolare": true, "rigorista": false, "punti_attesi": 6.1},
              {"id": 5, "nome": "Giocatore 044", "ruolo": "A", "avversario": "milan", "in_casa": false, "data_partita": "2026-10-31 18:30", "stato": "dubbio", "percentuale": 55, "dubbio": true, "diffidato": false, "titolare": true, "rigorista": true},
              {"id": 7, "nome": "Riserva", "ruolo": "C", "avversario": "lazio", "in_casa": true, "data_partita": "2026-10-31 15:00", "stato": "infortunato", "titolare": false},
              {"id": 8, "nome": "Senza Partita", "ruolo": "D", "stato": "disponibile"}],
     "squalificati": [9], "diffidati": [2], "rigoristi": [5],
     "diario": [{"giornata": 10, "attesi": 66.0, "fatti": 63.5}, {"giornata": 9, "attesi": 67.0, "fatti": 71.0}],
     "osservati": [{"id": 30, "nome": "Osservato", "ruolo": "A", "voto_atteso": 6.8, "punti_attesi": 7.1, "avversario": "inter", "in_casa": true, "data_partita": "2026-11-01 12:30", "stato": "disponibile", "percentuale": 90}],
     "dati": {"ultimo_aggiornamento": "2026-10-30 14:32"},
     "scambio": {"mia": "Schiera FC", "altra": "Real Madrink", "do": [{"id": 1, "nome": "A", "ruolo": "C"}], "ricevo": [{"id": 2, "nome": "B", "ruolo": "C"}], "guadagno_mio": 2.4, "guadagno_loro": 1.1},
     "svincolato": {"esce": {"id": 7, "nome": "Riserva", "ruolo": "C"}, "entra": {"id": 40, "nome": "Svincolato", "ruolo": "C", "quotazione": 12}, "guadagno": 2.5, "fattibile": true},
     "mancano": []}
    """#

    private func riassunto() throws -> RiassuntoWidget {
        try XCTUnwrap(RiassuntoWidget.leggi(Data(Self.corpo.utf8)))
    }

    func testSiLeggeTuttoIlContratto() throws {
        let w = try riassunto()
        XCTAssertEqual(w.giornata, 11)
        XCTAssertEqual(w.formazione?.modulo, "3-4-3")
        XCTAssertEqual(w.formazione?.titolari?.count, 2)
        XCTAssertEqual(w.formazione?.titolari?.first?.avatar?.p, 2, "i tratti del volto arrivano col giocatore")
        XCTAssertEqual(w.creditiResidui, 12)
        XCTAssertEqual(w.diario?.count, 2)
        XCTAssertEqual(w.diario?.first?.fatti, 63.5)
        XCTAssertEqual(w.scambio?.guadagnoMio, 2.4)
        XCTAssertEqual(w.svincolato?.entra?.quotazione, 12)
        XCTAssertEqual(w.dati?.ultimoAggiornamento, "2026-10-30 14:32")
        XCTAssertEqual(w.osservati?.first?.votoAtteso, 6.8)
        XCTAssertEqual(w.squalificati, [9])
        XCTAssertNotNil(w.inizio)
    }

    func testUnServerSenzaLeParti() throws {
        let minimo = #"{"giornata": 3, "formazione": {"modulo": "4-4-2"}}"#
        let w = try XCTUnwrap(RiassuntoWidget.leggi(Data(minimo.utf8)))
        XCTAssertNil(w.scambio)
        XCTAssertNil(w.svincolato)
        XCTAssertTrue(w.daControllare.isEmpty)
        XCTAssertTrue(w.giocanoPresto().isEmpty)
    }

    func testIRispostaStranaNonRompe() {
        XCTAssertNil(RiassuntoWidget.leggi(Data()))
        XCTAssertNil(RiassuntoWidget.leggi(Data("non json".utf8)))
        XCTAssertNil(RiassuntoWidget.leggi(Data(repeating: 0x20, count: 300_000)))
    }

    func testChiGiocaPrestoEInOrdineDiOrarioSenzaInfortunati() throws {
        let w = try riassunto()
        let adesso = try XCTUnwrap(Quando.data("2026-10-31 12:00"))
        let giocano = w.giocanoPresto(dopo: adesso)
        XCTAssertEqual(giocano.map(\.id), [5, 1], "prima Giocatore 044 (18:30), poi Giocatore 089 (20:45); l'infortunato e chi non ha partita no")
        XCTAssertEqual(giocano.first?.oraBreve, "18:30")
        XCTAssertEqual(giocano.first?.partitaBreve, "@ MIL · 18:30")
        XCTAssertEqual(giocano.last?.partitaBreve, "vs ROM · 20:45")
        XCTAssertEqual(w.giocanoPresto(dopo: adesso, massimo: 1).count, 1)
    }

    func testChiHaGiaGiocatoDaOreNonCompare() throws {
        let w = try riassunto()
        let tardi = try XCTUnwrap(Quando.data("2026-10-31 23:30"))
        XCTAssertTrue(w.giocanoPresto(dopo: tardi).isEmpty)
        let appenaFinita = try XCTUnwrap(Quando.data("2026-10-31 19:00"))
        XCTAssertEqual(w.giocanoPresto(dopo: appenaFinita).map(\.id), [5, 1], "una partita iniziata da meno di 2 ore e' ancora in corso")
    }

    func testLoStatoInUnaRiga() throws {
        let w = try riassunto()
        XCTAssertEqual(w.rosa?[1].descrizioneStato, "Dubbio 55%")
        XCTAssertEqual(w.rosa?[2].descrizioneStato, "Infortunato")
        XCTAssertEqual(w.rosa?[0].descrizioneStato, "Disponibile")
        XCTAssertEqual(w.avvisi?.first?.descrizioneStato, "Dubbio 55%")
    }

    func testIlRiassuntoVecchioDeiWidgetViene() throws {
        let w = try riassunto()
        let r = try XCTUnwrap(w.comeRiassuntoOggi())
        XCTAssertEqual(r.giornata, 11)
        XCTAssertEqual(r.modulo, "3-4-3")
        XCTAssertEqual(r.punti, 73.7)
        XCTAssertEqual(r.daControllare, 1)
        XCTAssertEqual(r.dubbi?.first?.id, 5)
        XCTAssertEqual(r.probabili, true)
    }

    func testIlCognome() {
        XCTAssertEqual(GiocatoreWidget(id: 1, nome: "Giocatore 002").cognome, "Giocatore 004")
        XCTAssertEqual(GiocatoreWidget(id: 1, nome: "Pedro").cognome, "Pedro")
    }
}

final class ScaricoWidgetTests: XCTestCase {
    private func sessione(_ gestore: @escaping (URLRequest) -> (Int, [String: String], Data)) -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [ProtocolloFinto.self]
        ProtocolloFinto.gestore = { r in
            let (codice, intestazioni, dati) = gestore(r)
            return (HTTPURLResponse(url: r.url ?? URL(fileURLWithPath: "/"), statusCode: codice, httpVersion: nil, headerFields: intestazioni) ?? HTTPURLResponse(), dati)
        }
        return URLSession(configuration: c)
    }

    override func tearDown() {
        ProtocolloFinto.gestore = nil
        super.tearDown()
    }

    func testScaricaConLEtagEIlTokenDelWidget() async {
        let visto = Scatola<[String]>()
        let s = sessione { r in
            visto.valore = [r.value(forHTTPHeaderField: "If-None-Match") ?? "-", r.value(forHTTPHeaderField: "Authorization") ?? "-", r.url?.path ?? ""]
            return (200, ["ETag": "\"abc\""], Data(WidgetRiassuntoTests.corpo.utf8))
        }
        let e = await ScaricoWidget.scarica(base: "https://prova-widget.invalid", token: "fw_tokenDiProva123456", etag: "\"vecchio\"", sessione: s)
        guard case .dati(let w, _, let etag) = e else { return XCTFail("atteso 200: \(e)") }
        XCTAssertEqual(w.giornata, 11)
        XCTAssertEqual(etag, "\"abc\"")
        XCTAssertEqual(visto.valore, ["\"vecchio\"", "Bearer fw_tokenDiProva123456", "/api/widget"])
    }

    func testIlCodiceDelServerSiTraduce() async {
        let casi: [(Int, String)] = [(304, "nonCambiato"), (202, "inCalcolo"), (401, "accessoRichiesto"), (404, "nonDisponibile"), (403, "nonDisponibile"), (500, "errore")]
        for (codice, nome) in casi {
            let s = sessione { _ in (codice, [:], Data("{}".utf8)) }
            let e = await ScaricoWidget.scarica(base: "https://prova-widget.invalid", token: nil, etag: nil, sessione: s)
            XCTAssertEqual("\(e)", nome, "codice \(codice)")
        }
    }

    func testUnCorpoRovinatoEUnErrore() async {
        let s = sessione { _ in (200, [:], Data("non json".utf8)) }
        let e = await ScaricoWidget.scarica(base: "https://prova-widget.invalid", token: nil, etag: nil, sessione: s)
        XCTAssertEqual("\(e)", "errore")
    }

    func testIndirizzoNonValidoEUnErrore() async {
        let e = await ScaricoWidget.scarica(base: "", token: nil, etag: nil)
        XCTAssertEqual("\(e)", "errore")
    }

    func testLaCopiaSiRicordaEPoiSiDimentica() throws {
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("copia-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        Condiviso.cartellaDiProva = cartella
        defer { Condiviso.cartellaDiProva = nil; try? FileManager.default.removeItem(at: cartella); MemoriaWidget.dimentica() }
        XCTAssertNil(MemoriaWidget.leggi())
        MemoriaWidget.salva(CopiaWidget(dati: Data(WidgetRiassuntoTests.corpo.utf8), etag: "\"e1\"", scaricatoIl: Date()))
        let c = try XCTUnwrap(MemoriaWidget.leggi())
        XCTAssertEqual(c.etag, "\"e1\"")
        XCTAssertEqual(c.riassunto?.giornata, 11)
        MemoriaWidget.dimentica()
        XCTAssertNil(MemoriaWidget.leggi())
    }
}
