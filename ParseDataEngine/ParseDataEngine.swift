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

enum ParseQueryOrder {
  case ascending, descending
}

public class ParseDataEngine<T>: NSObject, DataLoaderEngine where T: PFObject, T: CollectionRow {

  var skip: Int = 0
  
  public var queryLimit: Int { return 20 }

  var firstRow: PFObject?
  
  var searchKey: String = "name"
  var orderBy: String = "name"
  var order: ParseQueryOrder = .ascending
  
  func query(forLoadType loadType: DataLoadType, queryString: String?) -> PFQuery<PFObject> {
    let query: PFQuery<PFObject> = T.query()!
    
    if let queryString = queryString, !queryString.isEmpty {
      query.whereKey(searchKey, matchesRegex: queryString, modifiers: "i")
    }
    
    return query
  }
  
  public func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]> {
    if loadType == .clearAndReplace {
      skip = 0
    }
    
    let query: PFQuery<PFObject> = self.query(forLoadType: loadType, queryString: queryString)
    query.limit = queryLimit

    switch loadType {
    case .clearAndReplace,.replace,.initial:
      skip = 0
      query.skip = skip
    case .more:
      query.skip = skip
    case .newRows:
      if let firstOrder = firstRow?[orderBy] {
        switch order {
        case .ascending:
          query.whereKey(orderBy, lessThan: firstOrder)
        case .descending:
          query.whereKey(orderBy, greaterThan: firstOrder)
        }
      }
    }
    
    switch order {
    case .ascending:
      query.order(byAscending: orderBy)
    case .descending:
      query.order(byDescending: orderBy)
    }

    return Promise<[T]> { fulfill, reject in
      query.findObjectsInBackground() { results, error in
        if let error = error {
          reject(error)
        } else {
          if let results = results, results.count > 0 {
            if loadType != .more {
              self.firstRow = results.first
            }
            
            self.skip += results.count
          }
          
          fulfill(results as? [T] ?? [])
        }
        
      }
    }
  }
}

