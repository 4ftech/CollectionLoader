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

public func <~ <U: DataLoaderEngine, V: ViewMappable> (left: CollectionLoaderSelectRow<U, V>, right: (PFObject, String)) -> CollectionLoaderSelectRow<U, V> {
  let (object, key) = right
  
  left.onChange { row in
    object[key] = row.value?.objectId
  }
  if let id = object[key] as? String {
    let dataRow = U.T()
    dataRow.objectId = id
    
    left.value = dataRow
  }
  
  return left
}
