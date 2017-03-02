//
//  ParseDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader

import DataSource
import ParseDataSource

public class ParseDataEngine<T>: NSObject, DataLoaderEngine where T:ParseDataModel {
  public var skip: Int = 0
  
  public var firstRow: T?
  
  public var searchKey: String = "name"
  public var orderByKey: String? = "name"
  public var orderByLastValue: Any? {
    if let key = orderByKey {
      return firstRow?[key]
    } else {
      return nil
    }
  }
}

