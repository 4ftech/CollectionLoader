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

public class ParseDataEngine<T>: BaseDataLoaderEngine<T> where T:ParseDataModel {
  public override var paginate: Bool { return true }
  
  public override var searchKey: String { return "name" }
  public override var orderByKey: String? { return "createdAt" }
  public override var order: QueryOrder { return .descending }
  public override var orderByLastValue: Any? {
    if let key = orderByKey {
      return firstRow?[key]
    } else {
      return nil
    }
  }
  
}

