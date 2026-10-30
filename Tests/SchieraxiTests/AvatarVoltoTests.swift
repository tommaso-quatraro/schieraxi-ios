import XCTest
import SwiftUI
@testable import Schieraxi

/// Gli avatar illustrati devono dare GLI STESSI indici di web e Android (vettori di docs/AVATAR.md).
final class GeneratoreVoltoTests: XCTestCase {
    private func indici(_ v: [Int]) -> IndiciVolto {
        IndiciVolto(pelle: v[0], forma: v[1], acconciatura: v[2], colore: v[3], barba: v[4],
                    sopracciglia: v[5], occhi: v[6], bocca: v[7], accessorio: v[8], orecchie: v[9])
    }

    func testIVettoriDellaSpecifica() {
        let vettori: [Int: [Int]] = [
            1: [5, 0, 10, 0, 3, 1, 0, 1, 0, 1],
            2: [3, 0, 0, 1, 4, 0, 0, 1, 0, 0],
            3: [0, 2, 7, 7, 0, 0, 0, 0, 0, 0],
            100: [1, 2, 2, 7, 3, 0, 1, 0, 1, 1],
            4567: [2, 0, 0, 7, 0, 2, 2, 0, 0, 0],
            7627: [0, 0, 4, 1, 2, 1, 2, 0, 0, 0],
        ]
        for (id, atteso) in vettori {
            XCTAssertEqual(GeneratoreVolto.estrai(id: id), indici(atteso), "id \(id)")
        }
    }

    func testLeRegoleDiCoerenza() {
        // 140: orecchino (2) con acconciatura lunga (4) -> nessun accessorio; 170: fascia (1) con cresta (7) -> nessuno
        XCTAssertEqual(GeneratoreVolto.estraiGrezzo(id: 140), indici([3, 2, 4, 3, 1, 2, 0, 1, 2, 1]))
        XCTAssertEqual(GeneratoreVolto.estrai(id: 140), indici([3, 2, 4, 3, 1, 2, 0, 1, 0, 1]))
        XCTAssertEqual(GeneratoreVolto.estraiGrezzo(id: 170), indici([2, 2, 7, 7, 1, 1, 0, 1, 1, 0]))
        XCTAssertEqual(GeneratoreVolto.estrai(id: 170), indici([2, 2, 7, 7, 1, 1, 0, 1, 0, 0]))
    }

    func testMulberry32() {
        var a = GeneratoreVolto.Mulberry32(seme: 12345)
        for atteso in [0.9797282678, 0.3067522645, 0.4842054215] {
            XCTAssertEqual(a.prossimo(), atteso, accuracy: 1e-9)
        }
        var b = GeneratoreVolto.Mulberry32(seme: 0)
        for atteso in [0.2664292087, 0.0003297457] {
            XCTAssertEqual(b.prossimo(), atteso, accuracy: 1e-9)
        }
    }

    func testUnIdNonValidoVaLettoComeZero() {
        XCTAssertEqual(GeneratoreVolto.estrai(id: -5), GeneratoreVolto.estrai(id: 0))
        XCTAssertEqual(GeneratoreVolto.estrai(id: 5_000_000_000), GeneratoreVolto.estrai(id: 0))
        XCTAssertEqual(GeneratoreVolto.estrai(id: 4_294_967_295), GeneratoreVolto.estrai(id: 4_294_967_295), "il massimo è valido")
    }

    func testIPesiFannoCento() {
        for pesi in [GeneratoreVolto.pesiPelle, GeneratoreVolto.pesiForma, GeneratoreVolto.pesiAcconciatura, GeneratoreVolto.pesiColore,
                     GeneratoreVolto.pesiBarba, GeneratoreVolto.pesiSopracciglia, GeneratoreVolto.pesiOcchi, GeneratoreVolto.pesiBocca,
                     GeneratoreVolto.pesiAccessorio, GeneratoreVolto.pesiOrecchie] {
            XCTAssertEqual(pesi.reduce(0, +), 100)
        }
    }

    func testIVoltiSonoQuasiTuttiDiversi() {
        let diversi = Set((1...3000).map { GeneratoreVolto.estrai(id: $0).elenco })
        XCTAssertGreaterThan(diversi.count, 2950, "la specifica dichiara 2986 volti diversi su 3000 codici")
    }

    func testIColoriDerivatiConLArrotondamentoDellaSpecifica() {
        XCTAssertEqual(RGB8("#f6d5bd").scuri(0.14), RGB8(r: 212, g: 183, b: 163))   // floor(c * .86 + .5)
        XCTAssertEqual(RGB8("#000000").misce(RGB8("#ffffff"), 0.5), RGB8(r: 128, g: 128, b: 128))   // floor(255 * .5 + .5)
        XCTAssertEqual(RGB8("#ffffff").luminanza, 1, accuracy: 1e-9)
        XCTAssertEqual(RGB8("#000000").luminanza, 0, accuracy: 1e-9)
        XCTAssertEqual(RGB8("#1e71b8").esadecimale, "#1e71b8")
        XCTAssertEqual(RGB8("non un colore"), RGB8("#6b7280"), "un colore sbagliato dà il grigio")
    }

    func testLoSfondoSegueLaLuminanzaDellaMaglia() {
        // maglia chiara (juventus #f3f4f6): scura di .55 / .3, poi mescolata col secondo colore
        let chiara = GeneratoreVolto.sfondo(c1: RGB8("#f3f4f6"), c2: RGB8("#111827"))
        XCTAssertEqual(chiara.1, RGB8("#f3f4f6").scuri(0.3))
        XCTAssertEqual(chiara.0, RGB8("#f3f4f6").scuri(0.55).misce(RGB8("#111827"), 0.22))
        // maglia molto scura: si schiarisce
        let scura = GeneratoreVolto.sfondo(c1: RGB8("#0b2a52"), c2: RGB8("#111827"))
        XCTAssertEqual(scura.1, RGB8("#0b2a52").misce(RGB8("#ffffff"), 0.12))
    }
}

final class DisegnoVoltoTests: XCTestCase {
    func testIPercorsiSVG() {
        XCTAssertEqual(PercorsoSVG.path("M0 0H10V10H0Z").boundingRect, CGRect(x: 0, y: 0, width: 10, height: 10))
        // S riflette il secondo controllo precedente; numeri negativi
        let curva = PercorsoSVG.path("M0 0C0 10 10 10 10 0S20 -10 20 0")
        XCTAssertEqual(curva.boundingRect.maxX, 20, accuracy: 0.01)
        XCTAssertLessThan(curva.boundingRect.minY, 0)
        XCTAssertFalse(PercorsoSVG.path("M10 100C12 84 28 77 50 77S88 84 90 100Z").isEmpty)
        // più sottopercorsi
        let due = PercorsoSVG.path("M40 29Q42 22 46 19.5M50 28V19.5M60 29Q58 22 54 19.5")
        XCTAssertEqual(due.boundingRect.minX, 40, accuracy: 0.01)
        XCTAssertEqual(due.boundingRect.maxX, 60, accuracy: 0.01)
        XCTAssertTrue(PercorsoSVG.path("").isEmpty)
        _ = PercorsoSVG.path("M1")   // numeri mancanti: niente crash
    }

    func testOgniVoltoHaIlSuoDisegnoEIPortieriIGuanti() {
        let c1 = RGB8("#0a58a8"), c2 = RGB8("#111827")
        for id in 0..<400 {
            let campo = DisegnoVolto.elementi(id: id, portiere: false, c1: c1, c2: c2)
            let portiere = DisegnoVolto.elementi(id: id, portiere: true, c1: c1, c2: c2)
            XCTAssertGreaterThan(campo.count, 8, "id \(id)")
            XCTAssertEqual(portiere.count, campo.count + 4, "due guanti con due linee ciascuno? (id \(id))")
        }
    }

    func testIlColoreDellaSquadraEQuelloDellaWeb() {
        let (a, b) = DisegnoVolto.coloriSquadra("inter")
        XCTAssertEqual(a, RGB8("#0a58a8"))
        XCTAssertEqual(b, RGB8("#111827"))
        let (g1, g2) = DisegnoVolto.coloriSquadra(nil)
        XCTAssertEqual(g1, RGB8("#6b7280"))
        XCTAssertEqual(g2, RGB8("#e5e7eb"))
    }

    @MainActor
    func testIlVoltoSiDisegnaAdOgniDimensione() {
        for lato in [24.0, 40.0, 92.0] {
            let r = ImageRenderer(content: AvatarVolto(id: 4567, squadra: "milan", portiere: false).frame(width: lato, height: lato))
            r.scale = 1
            XCTAssertNotNil(r.uiImage, "lato \(lato)")
        }
    }
}
