import XCTest
@testable import Schieraxi

/// Decodifica delle risposte vere del server (copiate in `Tests/Fixtures` da una lega reale con il server locale).
final class ModelliTests: XCTestCase {
    func testOggi() throws {
        let o: Oggi = try Fixture.decodifica("oggi")
        XCTAssertEqual(o.giornata, 9)
        XCTAssertEqual(o.inizio, "2026-10-27 18:30")
        XCTAssertEqual(o.iniziata, true)
        XCTAssertEqual(o.conProbabili, true)
        XCTAssertEqual(o.formazione?.modulo, "4-3-3")
        XCTAssertEqual(o.formazione?.disponibile, true)
        XCTAssertEqual(o.avvisi?.count, 8)
        XCTAssertEqual(o.avvisi?.filter { $0.inFormazione == true }.count, 2)
        XCTAssertEqual(o.migliori?.count, 3)
        XCTAssertEqual(o.partite?.count, 10)
        XCTAssertEqual(o.partite?.first?.casa, "sassuolo")
    }

    func testFormazione() throws {
        let f: Formazione = try Fixture.decodifica("formazione")
        XCTAssertEqual(f.squadra, "Squadra Demo")
        XCTAssertEqual(f.giornata, 9)
        XCTAssertEqual(f.modulo, "4-3-3")
        XCTAssertEqual(f.titolari.count, 11)
        XCTAssertEqual(f.panchina.count, 11)
        XCTAssertEqual(f.livelli?.map(\.rischio), [-2, -1, 0, 1, 2])
        XCTAssertEqual(f.livelli?.first?.moduli.first?.titolari.count, 11)
        XCTAssertEqual(f.schede?.count, 25)
        XCTAssertEqual(f.fuori?.count, 3)
        XCTAssertEqual(f.senzaDati ?? [], [])
        XCTAssertEqual(f.dev, 4.0)
        // i campi della previsione ci sono tutti
        let vicario = try XCTUnwrap(f.titolari.first)
        XCTAssertEqual(vicario.nome, "Giocatore 094")
        XCTAssertEqual(vicario.ruolo, "P")
        XCTAssertEqual(vicario.titolarita, "titolare")
        XCTAssertEqual(vicario.indice, 100)
        XCTAssertNotNil(vicario.portaInviolata)
        XCTAssertEqual(vicario.motivi?.first, "titolare al 90%")
    }

    func testMercato() throws {
        let m: Mercato = try Fixture.decodifica("mercato")
        XCTAssertEqual(m.proposte.count, 10)
        XCTAssertEqual(m.svincolati, 353)
        XCTAssertNil(m.creditiResidui)
        XCTAssertEqual(m.rimborsoIpotizzato, 0.5)
        XCTAssertEqual(m.proposte.first?.esce.nome, "Giocatore 005")
        XCTAssertEqual(m.proposte.first?.giornate?.count, 5)
        XCTAssertNil(m.proposte.first?.creditiDopo)
    }

    func testClassifica() throws {
        let c: ElencoGiocatori = try Fixture.decodifica("classifica")
        XCTAssertEqual(c.giornata, 9)
        XCTAssertEqual(c.giocatori.count, 8)
        XCTAssertEqual(c.giocatori.first?.nome, "Giocatore 053")
        XCTAssertEqual(c.giocatori.first?.quotazione, 35)
        XCTAssertNotNil(c.giocatori.first?.proprietario)
    }

    func testProposteDiScambio() throws {
        let p: ProposteScambi = try Fixture.decodifica("proposte")
        XCTAssertEqual(p.proposte.count, 5)
        XCTAssertEqual(p.giornate, [9, 10, 11, 12, 13])
        let prima = try XCTUnwrap(p.proposte.first)
        XCTAssertEqual(prima.altra, "Lokomotiv Demo")
        XCTAssertEqual(prima.`do`.first?.nome, "Giocatore 036")
        XCTAssertEqual(prima.ricevo.first?.nome, "Giocatore 055")
        XCTAssertEqual(prima.guadagnoMio, 1.87, accuracy: 0.001)
        XCTAssertEqual(prima.perGiornataMio?.count, 5)
        // «reparti» è vuoto nelle proposte e non deve rompere la decodifica
        XCTAssertNil(prima.reparti?.mio)
        XCTAssertEqual(prima.quotazioneDo, 13)
    }

    func testRosa() throws {
        let r: Rosa = try Fixture.decodifica("rosa")
        XCTAssertEqual(r.nome, "Squadra Demo")
        XCTAssertEqual(r.mia, true)
        XCTAssertEqual(r.giocatori.count, 25)
        XCTAssertEqual(r.giocatori.first?.squadraSlug, "juventus")
        XCTAssertEqual(r.giocatori.first?.previsione?.titolarita, "titolare")
        XCTAssertEqual(r.avvisi?.count, 0)
        XCTAssertNil(r.creditiResidui)
    }

    func testRegoleComeJSONValue() throws {
        let v: JSONValue = try Fixture.decodifica("regole", snake: false)
        XCTAssertEqual(v.valore("nome_lega")?.testo, "La mia lega")
        XCTAssertEqual(v.valore("bonus.gol.D")?.numero, 3)
        XCTAssertEqual(v.valore("panchina.posti.D")?.numero, 3)
        XCTAssertEqual(v.valore("moduli")?.elenco?.count, 7)
        XCTAssertEqual(v.valore("modificatore_difesa.attivo")?.booleano, true)
        XCTAssertEqual(v.valore("voto_senza_sostituto"), JSONValue.nullo)
    }

    func testStatoDati() throws {
        let s: StatoDati = try Fixture.decodifica("stato-dati")
        XCTAssertEqual(s.stagione, "2026-27")
        XCTAssertEqual(s.partite?.giocate, 80)
        XCTAssertEqual(s.partite?.totali, 380)
        XCTAssertEqual(s.voti, 2542)
        XCTAssertEqual(s.foto, 4)
        XCTAssertEqual(s.probabili?.count, 1)
        XCTAssertEqual(s.calibrazione?.gruppi?.count, 7)
        // osservato e previsto sono null quando non ci sono dati
        XCTAssertNil(s.calibrazione?.gruppi?.first?.osservato)
        XCTAssertEqual(s.calibrazione?.gruppi?.first?.indicativo, true)
    }

    func testSquadre() throws {
        let s: [SquadraLega] = try Fixture.decodifica("squadre")
        XCTAssertEqual(s.count, 10)
        XCTAssertEqual(s.first?.nome, "Real Esempio")
        XCTAssertEqual(s.first?.immagini, ImmaginiSquadra(stemma: false, maglia: false))
        XCTAssertNil(s.first?.creditiResidui)
    }

    func testSchedaGiocatore() throws {
        let s: SchedaGiocatore = try Fixture.decodifica("giocatore")
        XCTAssertEqual(s.calciatore.nome, "Giocatore 053")
        XCTAssertEqual(s.calciatore.squadraSlug, "roma")
        XCTAssertEqual(s.stagione?.giornateGiocateSerieA, 8)
        XCTAssertEqual(s.voti?.count, 7)
        XCTAssertEqual(s.voti?.first?.giornata, 1)
        XCTAssertEqual(s.avanzate?.minuti, 492)
        XCTAssertEqual(s.avanzate?.per90?.xg, 1.22)
        XCTAssertEqual(s.avanzate?.stagioniPrecedenti?.count, 1)
        XCTAssertEqual(s.rendimento?.sovraRendimento, -0.29)
        XCTAssertEqual(s.previsione?.giornata, 9)
        XCTAssertEqual(s.proprietario, "Under Prova")
    }

    func testConfronto() throws {
        let c: Confronto = try Fixture.decodifica("confronto")
        XCTAssertEqual(c.giornata, 9)
        XCTAssertEqual(c.giocatori.count, 2)
        XCTAssertEqual(c.consigliato, 4409)
        XCTAssertEqual(c.fattori.count, 6)
        XCTAssertEqual(c.fattori.first?.chiave, "giocare")
        XCTAssertEqual(c.fattori.first?.percentuale, true)
        XCTAssertEqual(c.formazione?.postoA, "titolare")
        XCTAssertEqual(c.formazione?.modulo, "4-3-3")
    }

    func testAffidabilita() throws {
        let a: Affidabilita = try Fixture.decodifica("affidabilita")
        XCTAssertEqual(a.righe?.count, 8)
        XCTAssertEqual(a.sintesi?.giornate, 8)
        XCTAssertEqual(a.sintesi?.puntiModello, 71.7)
        XCTAssertEqual(a.righe?.first?.giornata, 1)
    }

    func testRegoleRiconosciute() throws {
        let r: RiconoscimentoRegole = try Fixture.decodifica("riconosci")
        XCTAssertEqual(r.modifiche.count, 1)
        XCTAssertEqual(r.modifiche.first?.chiave, "bonus.rigore_parato")
        XCTAssertEqual(r.modifiche.first?.valore.numero, 3)
        XCTAssertEqual(r.nonRiconosciute ?? [], [])
    }

    func testOffertaDaTesto() throws {
        let o: OffertaRiconosciuta = try Fixture.decodifica("da-testo")
        XCTAssertEqual(o.con, "Lokomotiv Demo")
        XCTAssertEqual(o.`do`, ["Giocatore 036"])
        XCTAssertEqual(o.ricevo, ["Giocatore 055"])
        XCTAssertEqual(o.ambigui ?? [], [])
        XCTAssertEqual(o.analisi?.reparti?.mio?["D"], 12.1)
        XCTAssertEqual(o.analisi?.percentualeMio, 0.2)
    }

    func testAsta() throws {
        let a: PianoAsta = try Fixture.decodifica("asta")
        XCTAssertEqual(a.crediti, 500)
        XCTAssertEqual(a.panchina, 60)
        XCTAssertEqual(a.ruoli.count, 4)
        XCTAssertEqual(a.ruoli.first?.giocatori.first?.nome, "Giocatore 094")
        XCTAssertEqual(a.ruoli.first?.giocatori.first?.prezzo, 65)
        let r: PianoRiparazione = try Fixture.decodifica("asta-riparazione")
        XCTAssertNil(r.tuoiCrediti)
        XCTAssertEqual(r.postiLiberi, 31)
        XCTAssertEqual(r.perTe?.count, 4)
        XCTAssertEqual(r.ruoli.map(\.ruolo), ["P", "D", "C", "A"])
        XCTAssertEqual(r.ruoli.first?.posti, 4)
    }

    func testAvvisiStagioneNovitaCalendario() throws {
        let a: StatoAvvisi = try Fixture.decodifica("avvisi", snake: false)
        XCTAssertTrue(a.impostazioni.cambi)
        XCTAssertEqual(a.impostazioni.app_nativa, false)
        XCTAssertEqual(a.dispositivi, 0)
        let s: StatoStagione = try Fixture.decodifica("stagione")
        XCTAssertEqual(s.nuova, false)
        XCTAssertEqual(s.corrente, "2026-27")
        let n: [VoceNovita] = try Fixture.decodifica("novita")
        XCTAssertEqual(n.map(\.versione), ["1.14", "1.13", "1.12"])
        let c: Calendario = try Fixture.decodifica("calendario")
        XCTAssertEqual(c.giornate, [9, 10, 11, 12, 13])
        XCTAssertEqual(c.squadre.count, 6)
        XCTAssertEqual(c.squadre.first?.partite.first?.avversario, "cagliari")
    }

    func testUnCampoMancanteNonRompeLaDecodifica() throws {
        // un giocatore con il solo necessario: tutto il resto è opzionale
        let json = #"{"id": 1, "nome": "Prova", "ruolo": "A"}"#
        let g: Giocatore = try Decodifica.decodifica(Data(json.utf8))
        XCTAssertEqual(g.nome, "Prova")
        XCTAssertNil(g.indice)
        XCTAssertTrue(g.etichette.isEmpty)
        // risposta senza «formazione» e senza «avvisi»
        let o: Oggi = try Decodifica.decodifica(Data(#"{"giornata": 3}"#.utf8))
        XCTAssertNil(o.formazione)
        XCTAssertNil(o.avvisi)
    }

    func testErroreDiDecodificaDaUnMessaggioInItaliano() {
        XCTAssertThrowsError(try Decodifica.decodifica(Data("{}".utf8)) as Oggi) { errore in
            XCTAssertTrue(errore.localizedDescription.hasPrefix("Risposta inattesa dal server"), errore.localizedDescription)
        }
    }

    func testImpostazioniAvvisiConAppNativaMancanteNonLaRimandano() throws {
        // un server vecchio non manda «app_nativa»: si legge come assente e non si rimanda (non si azzera niente)
        let vecchio = #"{"cambi": true, "promemoria_60": true, "promemoria_15": false, "riepilogo": true}"#
        let i = try JSONDecoder().decode(ImpostazioniAvvisi.self, from: Data(vecchio.utf8))
        XCTAssertNil(i.app_nativa)
        let rimandato = String(decoding: try JSONEncoder().encode(i), as: UTF8.self)
        XCTAssertFalse(rimandato.contains("app_nativa"))
        var nuova = i
        nuova.app_nativa = true
        XCTAssertTrue(String(decoding: try JSONEncoder().encode(nuova), as: UTF8.self).contains("\"app_nativa\":true"))
    }
}
