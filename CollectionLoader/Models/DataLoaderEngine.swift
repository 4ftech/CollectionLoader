//
//  DataLoaderEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import PromiseKit
import DataSource

public enum QueryOrder {
  case ascending, descending
}

public protocol DataLoaderEngine {
  associatedtype T: BaseDataModel
  
  var firstRow: T? { get set }
  var skip: Int { get set }
  
  var searchKey: String { get }
  
  // Have Defaults Below
  var orderByKey: String? { get }
  var orderByLastValue: Any? { get }

  var queryLimit: Int { get }
  var order: QueryOrder { get }
  
  mutating func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]>
}

public extension DataLoaderEngine {
  public var queryLimit: Int { return 20 }
  public var order: QueryOrder { return .ascending }
  public var orderByKey: String? { return nil }
  public var orderByLastValue: Any? { return nil }
  
  public mutating func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]> {
    if loadType == .clearAndReplace {
      skip = 0
    }

    let request: FetchRequest = T.fetchRequest()
    
    if let queryString = queryString {
      request.whereKey(searchKey, matchesRegex: queryString, modifiers: "i")
    }
    
    request.limit = queryLimit
    
    switch loadType {
    case .clearAndReplace,.replace,.initial:
      skip = 0
      request.offset = skip
    case .more:
      request.offset = skip
    case .newRows:
      if let firstOrder = orderByLastValue, let orderByKey = orderByKey {
        switch order {
        case .ascending:
          request.whereKey(orderByKey, lessThan: firstOrder)
        case .descending:
          request.whereKey(orderByKey, greaterThan: firstOrder)
        }
      }
    }
    
    if let orderByKey = orderByKey {
      switch order {
      case .ascending:
        request.orderByAscending(orderByKey)
      case .descending:
        request.orderByDescending(orderByKey)
      }
    }
    
    var realSelf = self    
    return Promise<[T]> { fulfill, reject in
      request.fetch().then { (results: [T]) -> Void in
        if results.count > 0 {
          if loadType != .more {
            realSelf.firstRow = results.first
          }
          
          realSelf.skip += results.count
        }

        fulfill(results)
      }.catch { error in
        reject(error)
      }
    }
  }
  
  public mutating func handle(results: [T], forLoadType loadType: DataLoadType) {
    if results.count > 0 {
      if loadType != .more {
        firstRow = results.first
      }
      
      skip += results.count
    }
  }
}
