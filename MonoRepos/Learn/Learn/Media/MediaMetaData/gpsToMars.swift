//
//  gpsToMars.swift
//  Learn
//
//  Created by tigerguo on 2024/11/8.
//

import CoreLocation
import Foundation

enum KSCoordinateConverter {
  static let x_pi = 3.14159265358979324 * 3000.0 / 180.0

  static func bd_encrypt(gg_lat: Double, gg_lon: Double) -> (bd_lat: Double, bd_lon: Double) {
    let x = gg_lon, y = gg_lat
    let z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi)
    let theta = atan2(y, x) + 0.000003 * cos(x * x_pi)
    let bd_lon = z * cos(theta) + 0.0065
    let bd_lat = z * sin(theta) + 0.006
    return (bd_lat, bd_lon)
  }

  static func bd_decrypt(bd_lat: Double, bd_lon: Double) -> (gg_lat: Double, gg_lon: Double) {
    let x = bd_lon - 0.0065, y = bd_lat - 0.006
    let z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi)
    let theta = atan2(y, x) - 0.000003 * cos(x * x_pi)
    let gg_lon = z * cos(theta)
    let gg_lat = z * sin(theta)
    return (gg_lat, gg_lon)
  }

  static func bdCoordinate(fromGPSCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let marsCoordinate = marsCoordinate(fromGPSCoordinate: coordinate)
    return bdCoordinate(fromMarsCoordinate: marsCoordinate)
  }

  static func gpsCoordinate(fromBDCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let marsCoordinate = marsCoordinate(fromBDCoordinate: coordinate)
    return gpsCoordinate(fromMarsCoordinate: marsCoordinate)
  }

  static func gpsCoordinate(fromMarsCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let marsCoordinate = marsCoordinate(fromGPSCoordinate: coordinate)
    var latitude = marsCoordinate.latitude - coordinate.latitude
    var longitude = marsCoordinate.longitude - coordinate.longitude
    latitude = coordinate.latitude - latitude
    longitude = coordinate.longitude - longitude
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  static func marsCoordinate(fromGPSCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let a = 6_378_245.0
    let ee = 0.00669342162296594323

    if isLocationOutOfChina(coordinate) {
      return coordinate
    }

    var dLat = transformLatitude(x: coordinate.longitude - 105.0, y: coordinate.latitude - 35.0)
    var dLon = transformLongitude(x: coordinate.longitude - 105.0, y: coordinate.latitude - 35.0)
    let radLat = coordinate.latitude / 180.0 * .pi
    var magic = sin(radLat)
    magic = 1 - ee * magic * magic
    let sqrtMagic = sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
    let latitude = coordinate.latitude + dLat
    let longitude = coordinate.longitude + dLon
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  static func bdCoordinate(fromMarsCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let (latitude, longitude) = bd_encrypt(gg_lat: coordinate.latitude, gg_lon: coordinate.longitude)
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  static func marsCoordinate(fromBDCoordinate coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let (latitude, longitude) = bd_decrypt(bd_lat: coordinate.latitude, bd_lon: coordinate.longitude)
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  static func transformLatitude(x: Double, y: Double) -> Double {
    var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
    ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
    ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
    ret += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
    return ret
  }

  static func transformLongitude(x: Double, y: Double) -> Double {
    var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
    ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
    ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
    ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
    return ret
  }

  static func isLocationOutOfChina(_ location: CLLocationCoordinate2D) -> Bool {
    let point = CGPoint(x: location.latitude, y: location.longitude)
    var oddFlag = false
    let polygon = polygonOfChina()
    var j = polygon.count - 1
    for i in 0 ..< polygon.count {
      let polygonPointi = polygon[i].cgPointValue
      let polygonPointj = polygon[j].cgPointValue
      if ((polygonPointi.y < point.y && polygonPointj.y >= point.y) ||
        (polygonPointj.y < point.y && polygonPointi.y >= point.y)) &&
        (polygonPointi.x <= point.x || polygonPointj.x <= point.x) {
        oddFlag.toggle()
      }
      j = i
    }
    return !oddFlag
  }

  static func polygonOfChina() -> [NSValue] {
    var polygonOfChina: [NSValue] = []
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 49.1506690000, y: 87.4150810000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 48.3664501790, y: 85.7527085300)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 47.0253058185, y: 85.3847443554)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 45.2406550000, y: 82.5214000000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 44.8957121295, y: 79.9392351487)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 43.1166843846, y: 80.6751253982)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 41.8701690000, y: 79.6882160000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 39.2896190000, y: 73.6171080000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 34.2303430000, y: 78.9155300000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 31.0238860000, y: 79.0627080000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 27.9989800000, y: 88.7028920000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 27.1793590000, y: 88.9972480000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 28.0969170000, y: 89.7331400000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 26.9157800000, y: 92.1615830000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 28.1947640000, y: 96.0986050000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 27.4094760000, y: 98.6742270000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 23.9085500000, y: 97.5703890000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 24.0775830000, y: 98.7846100000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.1375640000, y: 99.1893510000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 21.1398950000, y: 101.7649720000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.2746220000, y: 101.7281780000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 23.2641940000, y: 105.3708430000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.7191200000, y: 106.6954480000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 21.9945711661, y: 106.7256731791)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 21.4847050000, y: 108.0200530000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 20.4478440000, y: 109.3814530000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 18.6689850000, y: 108.2408210000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 17.4017340000, y: 109.9333720000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 19.5085670000, y: 111.4051560000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 21.2716775175, y: 111.2514995205)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 21.9936323233, y: 113.4625292629)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.1818312942, y: 113.4258358111)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.2249729295, y: 113.5913115000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.4501912753, y: 113.8946844490)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.5959159322, y: 114.3623797842)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.4334610000, y: 114.5194740000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 22.9680954377, y: 116.8326939975)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 25.3788220000, y: 119.9667980000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 28.3261276204, y: 121.7724402562)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 31.9883610000, y: 123.8808230000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 39.8759700000, y: 124.4695370000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 41.7350890000, y: 126.9531720000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 41.5142160000, y: 128.3145720000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 42.9842081790, y: 131.0676468344)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 45.2690810000, y: 131.8468530000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 45.0608370000, y: 133.0610740000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 48.4480260000, y: 135.0111880000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 48.0054800000, y: 131.6628800000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 50.2270740000, y: 127.6890640000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 53.3516070000, y: 125.3710040000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 53.4176040000, y: 119.9254040000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 47.5590810000, y: 115.1421070000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 47.1339370000, y: 119.1159230000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 44.8256460000, y: 111.2786750000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 42.5293560000, y: 109.2549720000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 43.2598160000, y: 97.2967290000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 45.4247620000, y: 90.9680590000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 47.8075570000, y: 90.6737020000)))
    polygonOfChina.append(NSValue(cgPoint: CGPoint(x: 49.1506690000, y: 87.4150810000)))
    return polygonOfChina
  }
}
