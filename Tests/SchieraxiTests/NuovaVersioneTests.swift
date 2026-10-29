import XCTest
@testable import Schieraxi

final class NuovaVersioneTests: XCTestCase {
    func testNumeroDalTag() {
        XCTAssertEqual(NuovaVersione.numero(daTag: "build-37"), 37)
        XCTAssertNil(NuovaVersione.numero(daTag: "v1.2"))
    }

    func testSoloUnaBuildPiuNuovaVieneSegnalata() {
        XCTAssertEqual(NuovaVersione.piuNuova(tag: "build-38", installata: 37), 38)
        XCTAssertNil(NuovaVersione.piuNuova(tag: "build-37", installata: 37))   // stessa build: niente
        XCTAssertNil(NuovaVersione.piuNuova(tag: "build-36", installata: 37))   // più vecchia: niente
        XCTAssertNil(NuovaVersione.piuNuova(tag: "strano", installata: 1))      // tag non riconosciuto: niente
    }
}
