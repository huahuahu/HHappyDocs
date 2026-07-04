//
//  AttributeStringTest.swift
//  LibaiTests
//
//  Created by huahuahu on 2022/5/29.
//

import XCTest

class AttributeStringTest: XCTestCase {
  func testRangeOf() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    var attributeString = AttributedString("""
    在洛阳相遇。当时杜甫也在苦闷之中，非常仰慕李白，出席了洛阳人士为李白洗尘的宴会。宴会散场后，杜甫留在了李白寓所倾心畅谈，直到深夜。俩人意气相投，“醉眠秋共被，携手日同行”，结下了深厚的友谊。
    秋天，和杜甫、高适同游梁宋。
    遭受打击的李白开始走向求道隐世之路。李白返回任城，先是盖了一间酒楼，邀请裴家叔侄和孔巢父等人来聚饮。然后修建了一间炼丹房，吃丹药还拉起了肚子，故意消磨自己的壮志。
    十月李白来到安陵找到盖寰道士把《道
    """)
    let range = attributeString.range(of: "杜甫")!
    attributeString[range].foregroundColor = .yellow
    print("before remove \(attributeString)")
    let newRange = range.lowerBound ..< range.upperBound
    attributeString = AttributedString(attributeString[newRange])

    print("after remove \(attributeString)")
  }
}
