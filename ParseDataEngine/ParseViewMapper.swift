//
//  ParseViewMapper.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/2/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper
import Eureka
import Parse
import DataSource
import CollectionLoader
import ParseEurekaViewMapper

infix operator <~

public func <~ <T: CellMapperAdapter, U: DataLoaderEngine> (left: CollectionLoaderSelectRow<T, U>, right: (PFObject, String)) -> CollectionLoaderSelectRow<T, U> {
  let (object, key) = right
  
  left.onChange { row in
    if let value = row.value?.objectId {
      object[key] = value
    } else {
      object.remove(forKey: key)
    }
  }
  
  if let id = object[key] as? String {
    let dataRow = U.T()
    dataRow.objectId = id
    
    left.value = dataRow
  }
  
  return left
}


public func <~ <T: CellMapperAdapter, U: DataLoaderEngine> (left: CollectionLoaderSelectMultipleRow<T, U>, right: (PFObject, String)) -> CollectionLoaderSelectMultipleRow<T, U> {
  let (object, key) = right
  
  left.onChange { row in
    let ids = row.value?.filter { $0.objectId != nil }.map { $0.objectId! } ?? []
    if ids.count > 0 {
      object[key] = ids
    } else {
      object.remove(forKey: key)
    }
  }
  
  if let ids = object[key] as? [String] {
    let dataRows = ids.map { id -> U.T in
      let row = U.T()
      row.objectId = id
      
      return row
    }
    
    left.value = Set<U.T>(dataRows)
  }
  
  return left
}
