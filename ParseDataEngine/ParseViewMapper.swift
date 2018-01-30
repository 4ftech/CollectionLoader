//
//  ParseViewMapper.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/2/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper
import Eureka
import Parse
import DataSource
import CollectionLoader
import ParseEurekaViewMapper

infix operator <~

public func <~ <C, E> (left: CollectionLoaderSelectRow<C, E>, right: (PFObject, String)) -> CollectionLoaderSelectRow<C, E> {
  let (object, key) = right
  
  left.onChange { row in
    if let value = row.value?.objectId {
      object[key] = value
    } else {
      object.remove(forKey: key)
    }
  }
  
  if let id = object[key] as? String {
    let dataRow = C.T.T()
    dataRow.objectId = id
    
    left.value = dataRow
  }
  
  return left
}


public func <~ <C, E> (left: CollectionLoaderSelectMultipleRow<C, E>, right: (PFObject, String)) -> CollectionLoaderSelectMultipleRow<C, E> {
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
    let dataRows = ids.map { id -> C.T.T in
      let row = C.T.T()
      row.objectId = id
      
      return row
    }
    
    left.value = Set<C.T.T>(dataRows)
  }
  
  return left
}
