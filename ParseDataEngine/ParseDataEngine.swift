//
//  ParseDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import CollectionLoader

import DataSource
import ParseDataSource

open class ParseDataEngine<T>: BaseDataLoaderEngine<T> where T:ParseDataModel {
  public required init() {
    super.init()
    
    self.searchKey = "name"
    self.orderByKey = "createdAt"
    self.order = .descending
  }
  
  open override var orderByLastValue: Any? {
    return firstRow?.createdAt
  }
  
}

