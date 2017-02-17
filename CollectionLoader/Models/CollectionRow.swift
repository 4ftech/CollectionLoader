//
//  CollectionRow.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol CollectionRow: class, Equatable, Hashable {
  var objectId: String? { get }
  var updatedAt: Date? { get }
  
  var name: String? { get }
}

public extension CollectionRow {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    if let lhsId = lhs.objectId, let rhsId = rhs.objectId {
      return lhsId == rhsId
    } else {
      return lhs.name == rhs.name
    }
  }
  
  var hashValue: Int {
    return objectId?.hashValue ?? name?.hashValue ?? 0
  }
}
