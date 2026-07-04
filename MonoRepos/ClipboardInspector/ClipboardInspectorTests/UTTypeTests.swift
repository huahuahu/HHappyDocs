//
//  UTTypeTests.swift
//  ClipboardInspectorTests
//
//  Created by tigerguo on 2023/3/16.
//

import UniformTypeIdentifiers
import XCTest

final class ClipboardInspectorTests: XCTestCase {
  func testSupertype() throws {
    let jpeg = UTType.jpeg
    XCTAssertEqual(jpeg.identifier.lowercased(), "public.jpeg")
    let superTypes = jpeg.supertypes.map { $0.identifier }.sorted(by: <)
    XCTAssertEqual(superTypes.count, 4)
    XCTAssertEqual(superTypes, ["public.content", "public.data", "public.image", "public.item"])
  }
}
