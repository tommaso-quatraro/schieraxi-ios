import XCTest
@testable import Schieraxi

final class FormatoTests: XCTestCase {
    /// Il segno meno può essere «-» o «−» secondo il sistema: si confronta con un solo carattere.
    private func normalizza(_ t: String) -> String { t.replacingOccurrences(of: "\u{2212}", with: "-") }

    func testVirgolaDecimaleSempreInItaliano() {
        XCTAssertEqual(Formato.decimali(6.26), "6,3")
        XCTAssertEqual(Formato.decimali(6, cifre: 2), "6,00")
    }

    func testPuntiConValoreMancanteVaZero() {
        XCTAssertEqual(Formato.punti(nil), "0,0")
        XCTAssertEqual(Formato.punti(7.44), "7,4")
    }

    func testConSegno() {
        XCTAssertEqual(Formato.conSegno(2.5), "+2,5")
        XCTAssertEqual(normalizza(Formato.conSegno(-1.2)), "-1,2")
        XCTAssertEqual(Formato.conSegno(0), "+0,0")
        XCTAssertEqual(Formato.conSegno(3.456, cifre: 2), "+3,46")
    }

    func testPercento() {
        XCTAssertEqual(Formato.percento(0.456), 46)
        XCTAssertEqual(Formato.percento(1), 100)
        XCTAssertEqual(Formato.percento(nil), 0)
    }

    func testInteroNonVaMaiInCrash() {
        XCTAssertEqual(Formato.intero(3.9), 3)
        XCTAssertEqual(Formato.intero(-2.5), -2)
        XCTAssertEqual(Formato.intero(nil), 0)
        XCTAssertEqual(Formato.intero(.nan), 0)
        XCTAssertEqual(Formato.intero(.infinity), 0)
        XCTAssertEqual(Formato.intero(1e20), 0)
    }

    func testDifficoltaAParole() {
        XCTAssertEqual(Formato.difficolta(1), "molto facile")
        XCTAssertEqual(Formato.difficolta(2), "facile")
        XCTAssertEqual(Formato.difficolta(nil), "difficoltà media")
        XCTAssertEqual(Formato.difficolta(4), "difficile")
        XCTAssertEqual(Formato.difficolta(5), "molto difficile")
        XCTAssertEqual(Formato.difficolta(0), "molto facile")
    }
}
