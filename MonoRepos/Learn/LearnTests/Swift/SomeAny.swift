//
//  SomeAny.swift
//  LearnTests
//
//  Created by tigerguo on 2023/4/9.
//

import XCTest

// https://swiftsenpai.com/swift/understanding-some-and-any/
// https://juejin.cn/post/7119062263406788616
// Therefore, even though Apple has made a lot of improvements on the any keyword, it is still recommended to use the some keyword if the opaque types can get the job done.

// https://www.swiftbysundell.com/articles/referencing-generic-protocols-with-some-and-any-keywords/
// using any does introduce type erasure under the hood

final class SomeAny: XCTestCase {
  func testSome() throws {
    // 1
//      we are telling the compiler that we are working on a specific concrete type, thus the opaque type’s underlying type must be fixed for the scope of the variable.
    // 不透明类型表示的隐式类型必须针对变量的生效范围是唯一的。
    var myCar: some Vehicle = Car() // Type of variable myCar is fixed
    // 编译器同样禁止将相同类型的新实例分配给变量。
//      myCar = Bus() // 🔴 Compile error: Cannot assign value of type 'Bus' to type 'some Vehicle'
//      myCar = Car() // 🔴 Compile error: Cannot assign value of type 'Car' to type 'some Vehicle'

    // 2
    var myCar1: some Vehicle = Car()
    var myCar2: some Vehicle = Car()
    print(type(of: myCar1))
    print(type(of: myCar2))
//      myCar2 = myCar1 // 🔴 Compile error: Cannot assign value of type 'some Vehicle' (type of 'myCar1') to type 'some Vehicle' (type of 'myCar2')

    // 3
    // ✅ No compile error
    let vehicles: [some Vehicle] = [
      Car(),
      Car(),
      Car(),
    ]

    // 🔴 Compile error: Cannot convert value of type 'Bus' to expected element type 'Car'
//      let vehicles1: [some Vehicle] = [
//          Car(),
//          Car(),
//          Bus(),
//      ]
  }

  private func createSomeVehicle(isPublicTransport: Bool) -> some Vehicle {
    if isPublicTransport {
      return Bus()
    }
    else {
      return Bus()
      // Return car won't compile as Car and Bus are not same type
//            return Car()
    }
  }

  private func wash(_ vehicle: some Vehicle) {
    // We can pass collection here
  }

  // MARK: some collection

  private func wash(_ vehicles: some Collection<Vehicle>) {
    // We can pass collection here
  }

  // Can also compile with any
//    private func bookmark(_ items: some Collection<any ContentItem>) {
  private func bookmark(_ items: some Collection<some ContentItem>) {}

  // MARK: any

  func testAny() {
//        let myCar1: Vehicle = Car() // 🔴 Compile error in Swift 5.7: Use of protocol 'Vehicle' as a type must be written 'any Vehicle'
//        an existential type is like a box that contains something that conforms to a specific protocol
    var myCar: any Vehicle = Car() // ✅ No compile error in Swift 5.7

    // ✅ No compile error when changing the underlying data type
    myCar = Bus()
    myCar = Car()

    // 🔴 Compile error in Swift 5.6: protocol 'Vehicle' can only be used as a generic constraint because it has Self or associated type requirements
    // ✅ No compile error in Swift 5.7
    let vehicles: [any Vehicle] = [
      Car(),
      Car(),
      Bus(),
    ]
  }

  // ✅ No compile error when returning different kind of concrete type
  private func createAnyVehicle1(isPublicTransport: Bool) -> any Vehicle {
    if isPublicTransport {
      return Bus()
    }
    else {
      return Car()
    }
  }

  // MARK: any limitation

  func testEqual() {
    var myCar1 = createAnyVehicle1(isPublicTransport: false)
    var myCar2 = createAnyVehicle1(isPublicTransport: false)
//        let isSameVehicle1 = myCar1 == myCar2 // 🔴 Compile error: Binary operator '==' cannot be applied to two 'any Vehicle' operands

    let myCarSome1 = createSomeVehicle(isPublicTransport: true)
    let myCarSome2 = createSomeVehicle(isPublicTransport: false)
    let isSameVehicle = myCarSome1 == myCarSome2 // ✅ No compile error
  }
}

private protocol Vehicle: Equatable {
  var name: String { get }

  associatedtype FuelType
  func fillGasTank(with fuel: FuelType)
}

private protocol ContentItem: Identifiable where ID == UUID {
  var title: String { get }
  var imageURL: URL { get }
}

private struct Car: Vehicle {
  let name = "car"

  func fillGasTank(with fuel: Gasoline) {
    print("Fill \(name) with \(fuel.name)")
  }
}

private struct Bus: Vehicle {
  let name = "bus"

  func fillGasTank(with fuel: Diesel) {
    print("Fill \(name) with \(fuel.name)")
  }
}

private struct Gasoline {
  let name = "gasoline"
}

private struct Diesel {
  let name = "diesel"
}
