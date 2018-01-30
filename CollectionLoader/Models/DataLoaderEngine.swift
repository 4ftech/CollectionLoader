//
//  DataLoaderEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import PromiseKit
import DataSource

public enum QueryOrder {
  case ascending, descending
}

//public protocol DataLoaderEngine {
//  associatedtype T: BaseDataModel
//
//  var paginate: Bool { get set }
//  var queryLimit: Int? { get set }
//  var skip: Int { get set }
//  var firstRow: T? { get set }
//
//  var searchKey: String? { get }
//
//  var orderByKey: String? { get }
//  var orderByLastValue: Any? { get }
//  var order: QueryOrder { get }
//
//  var filterFunction: ((T) -> Bool)? { get set }
//  var sortFunction: ((T, T) -> Bool)? { get set }
//
//  init()
//
//  mutating func promise(forLoadType loadType: DataLoadType, queryString: String?, filters: [Filter]?) -> Promise<[T]>
//}


open class DataLoaderEngine<T: BaseDataModel>: NSObject {
  open var paginate: Bool = false
  open var queryLimit: Int? = nil
  open var skip: Int = 0
  open var firstRow: T?
  
  open var searchKey: String?
  open var orderByKey: String?
  open var order: QueryOrder = .ascending
  
  open var orderByLastValue: Any? { return nil }
  
  open var filterFunction: ((T) -> Bool)? = nil
  open var sortFunction: ((T, T) -> Bool)? = nil
    
  public required override init() {
    super.init()
  }
  
  open func add(queryString: String, searchKey: String, toRequest request: inout FetchRequest) {
    request.whereKey(searchKey, matchesRegex: queryString, modifiers: "i")
  }
  
  open func request(forLoadType loadType: DataLoadType, queryString: String?, filters: [Filter]?) -> FetchRequest {
    var request: FetchRequest = T.fetchRequest()
    
    if let queryString = queryString, let searchKey = searchKey {
      add(queryString: queryString, searchKey: searchKey, toRequest: &request)
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
    
    return request.apply(filters: filters)
  }
  
  open func promiseForRequest(fetchRequest: FetchRequest) -> Promise<[T]> {
    return T.sharedDataSource.fetch(request: fetchRequest)
  }
  
  open func promiseForFetch(forLoadType loadType: DataLoadType, queryString: String?, filters: [Filter]?) -> Promise<[T]> {
    let request: FetchRequest = self.request(forLoadType: loadType, queryString: queryString, filters: filters)
    return self.promiseForRequest(fetchRequest: request)
  }
  
  open func promise(forLoadType loadType: DataLoadType = .initial, queryString: String? = nil, filters: [Filter]?  = nil) -> Promise<[T]> {
    if loadType == .newRows && orderByKey != nil && orderByLastValue == nil {
      return Promise(value: [])
    }
    
    return Promise<[T]> { fulfill, reject in
      self.promiseForFetch(forLoadType: loadType, queryString: queryString, filters: filters).then { (results: [T]) -> Void in
        if loadType != .more {
          self.firstRow = results.first
        }
        
        if self.paginate {
          if loadType == .more || loadType == .newRows {
            self.skip += results.count
          } else {
            self.skip = results.count
          }
        }
        
        fulfill(results)
      }.catch { error in
        reject(error)
      }
    }
  }
}

open class BaseDataLoaderEngine<T: BaseDataModel>: DataLoaderEngine<T> {
  
}

open class NestedDataLoaderEngine<T: BaseDataModel, U: BaseDataModel>: BaseDataLoaderEngine<T> {
  public var parentObject: U!
  
  public init(parentObject: U) {
    super.init()
    
    self.parentObject = parentObject
  }
  
  public required init() {
    super.init()
  }
  
  open override func promiseForRequest(fetchRequest: FetchRequest) -> Promise<[T]> {
    return T.sharedDataSource.fetch(request: fetchRequest, forParentObject: parentObject)
  }
}
