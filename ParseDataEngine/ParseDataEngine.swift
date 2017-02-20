//
//  ParseDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import BoltsSwift
import Parse

open class ParseCollectionObject: NSObject, CollectionRow {
  var parseObject: PFObject?
  
  public init(parseObject: PFObject) {
    super.init()
    
    self.parseObject = parseObject
  }
  
  open var objectId: String? {
    return parseObject?.objectId
  }
  
  public var updatedAt: Date? {
    return parseObject?.updatedAt
  }
  
  open var name: String? {
    return parseObject?["name"] as? String
  }
}

public class ParseDataEngine: NSObject, DataLoaderEngine {
  enum Order {
    case ascending, descending
  }
  
  var skip: Int = 0
  
  public var queryLimit: Int { return 20 }

  var firstRow: PFObject?
  
  var parseClassName: String?
  var subclassedType: PFObject.Type?
  
  var searchKey: String = "name"
  var orderBy: String = "name"
  var order: Order = .ascending
  
  public init(parseClassName: String? = nil, subclassedType: PFObject.Type? = nil) {
    super.init()
    
    self.parseClassName = parseClassName
    self.subclassedType = subclassedType
  }
  
  func query(forLoadType loadType: DataLoadType, queryString: String?) -> PFQuery<PFObject> {
    var query: PFQuery<PFObject>!
    if let parseClassName = parseClassName {
      query = PFQuery<PFObject>(className: parseClassName)
    } else if let subclassedType = subclassedType {
      query = subclassedType.query()!
    } else {
      query = PFQuery()
    }
    
    if let queryString = queryString, !queryString.isEmpty {
      query.whereKey(searchKey, matchesRegex: queryString, modifiers: "i")
    }
    
    return query
  }
  
  public func task(forLoadType loadType: DataLoadType, queryString: String?) -> Task<NSArray> {
    if loadType == .clearAndReplace {
      skip = 0
    }
    
    let task = TaskCompletionSource<NSArray>()
    
    let query: PFQuery = self.query(forLoadType: loadType, queryString: queryString)
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
    
    query.findObjectsInBackground().continue({ parseTask in
      
      if let error = parseTask.error {
        NSLog("Error: \(error)")
        task.set(error: error)
      } else if let results = parseTask.result as? [PFObject], results.count > 0 {
        if loadType != .more {
          self.firstRow = results.first
        }
        
        self.skip += results.count
        
        if let _ = self.subclassedType {
          // Assume the subclassedType also conforms to CollectionRow
          task.set(result: NSArray(array: results))
        } else {
          task.set(result: NSArray(array: results.map { ParseCollectionObject(parseObject: $0) }))
        }
      } else {
        task.set(result: [])
      }
      
      return nil
    })
    
    return task.task
  }
}

