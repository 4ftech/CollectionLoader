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
  
  var paginate: Bool { get }  
  var firstRow: T? { get set }
  
  var searchKey: String? { get }
  
  var orderByKey: String? { get }
  var orderByLastValue: Any? { get }
  var order: QueryOrder { get }

  var queryLimit: Int? { get }
  var skip: Int { get set }

  
  mutating func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]>
}


open class BaseDataLoaderEngine<U: BaseDataModel>: NSObject, DataLoaderEngine {
  public typealias T = U

  open var paginate: Bool { return false }
  public var firstRow: U?
  
  open var searchKey: String? { return nil }
  
  open var orderByKey: String? { return nil }
  open var orderByLastValue: Any? { return nil }
  open var order: QueryOrder { return .ascending }
  
  open var queryLimit: Int? { return nil }
  public var skip: Int = 0
  
  open func request(forLoadType loadType: DataLoadType, queryString: String?) -> FetchRequest {
    let request: FetchRequest = T.fetchRequest()
    
    if let queryString = queryString, let searchKey = searchKey {
      request.whereKey(searchKey, matchesRegex: queryString, modifiers: "i")
    }
    
    request.limit = queryLimit
    
    switch loadType {
    case .clearAndReplace,.replace,.initial:
      if paginate {
        skip = 0
        request.offset = skip
      }
    case .more:
      if paginate {
        request.offset = skip
      }
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
    
    return request
  }
  
  open func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[T]> {
    if loadType == .newRows && orderByLastValue == nil {
      return Promise(value: [])
    }
    
    let request: FetchRequest = self.request(forLoadType: loadType, queryString: queryString)
    
    let realSelf = self
    return Promise<[T]> { fulfill, reject in
      request.fetch().then { (results: [T]) -> Void in
        if loadType != .more {
          realSelf.firstRow = results.first
        }
        
        if realSelf.paginate {
          if loadType == .more || loadType == .newRows {
            realSelf.skip += results.count
          } else {
            realSelf.skip = results.count
          }
        }
        
        fulfill(results)
      }.catch { error in
        reject(error)
      }
    }
  }
}
