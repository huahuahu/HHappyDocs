//
//  HPhoto.swift
//  HDiary
//
//  Created by tigerguo on 2023/6/23.
//

#if os(iOS)

import CoreTransferable
import Foundation
import UIKit

struct HPhoto: Transferable {
  let image: UIImage?
  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(importedContentType: .image) { data in
      Self(image: UIImage(data: data))
    }
  }
}

#endif
