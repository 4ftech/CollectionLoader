//
//  ParseDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import PromiseKit
import Parse

import DataSource
import ParseDataSource

enum ParseQueryOrder {
  case ascending, descending
}

open class ParseCollectionRow: ParseDataModel, CollectionRow {
  open var name: String? {
    get {
      return self["name"] as? String
    }
    set {
      self["name"] = newValue
    }
  }
}

public class ParseDataEngine<T>: NSObject, DataLoaderEngine where T: CollectionRow, T: BaseDataModel {
  var skip: Int = 0
  
  public var queryLimit: Int { return 20 }

  var firstRow: PFObject?
  
  var searchKey: String = "name"
  var orderBy: String = "name"
  var order: ParseQueryOrder = .ascending
  
  public func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]> {
    if loadType == .clearAndReplace {
      skip = 0
    }

    let request: FetchRequest = T.fetchRequest()
    request.limit = queryLimit
    
    switch loadType {
    case .clearAndReplace,.replace,.initial:
      skip = 0
      request.offset = skip
    case .more:
      request.offset = skip
    case .newRows:
      if let firstOrder = firstRow?[orderBy] {
        switch order {
        case .ascending:
          request.whereKey(orderBy, lessThan: firstOrder)
        case .descending:
          request.whereKey(orderBy, greaterThan: firstOrder)
        }
      }
    }
    
    switch order {
    case .ascending:
      request.orderByAscending(orderBy)
    case .descending:
      request.orderByDescending(orderBy)
    }

    return Promise { fulfill, reject in
      request.fetch().then { (results: [T]) -> Void in
        if results.count > 0 {
          if loadType != .more {
            self.firstRow = results.first as? PFObject
          }
          
          self.skip += results.count
        }
        
        fulfill(results)
      }.catch { error in
        reject(error)
      }
    }
    
  }
}

