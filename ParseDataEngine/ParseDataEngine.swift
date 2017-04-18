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

open class ParseDataEngine<T>: BaseDataLoaderEngine<T> where T:ParseDataModel {
  open override var paginate: Bool { return true }
  
  open override var searchKey: String { return "name" }
  open override var orderByKey: String? { return "createdAt" }
  open override var order: QueryOrder { return .descending }
  open override var orderByLastValue: Any? {
    return firstRow?.createdAt
  }
  
}

