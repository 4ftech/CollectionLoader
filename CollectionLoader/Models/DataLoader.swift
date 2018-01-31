//
//  DataLoader.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//


import Foundation

import Changeset
import RxSwift
import UIScrollView_InfiniteScroll
import PromiseKit

import DataSource

enum DataLoaderAction: String {
  case ResultsReceived = "ResultsReceived", FinishedLoading = "FinishedLoading", CRUD = "CRUD"
}

public enum NewRowsPosition {
  case beginning, end
}

public protocol DataLoaderDelegate: class {
  func dataLoader<T, E>(_ dataLoader: DataLoader<T, E>, didInsertRowAtIndex index: Int)
  func dataLoader<T, E>(_ dataLoader: DataLoader<T, E>, didUpdateRowAtIndex index: Int)
  func dataLoader<T, E>(_ dataLoader: DataLoader<T, E>, didRemoveRowAtIndex index: Int)
  func dataLoader<T, E>(_ dataLoader: DataLoader<T, E>, didStartLoadingRowsWithLoadType loadType: DataLoadType)
  func dataLoader<T, E>(_ dataLoader: DataLoader<T, E>, didCatchLoadingError error: Error)
  func dataLoaderDidClearRows<T, E>(_ dataLoader: DataLoader<T, E>)
}

open class DataLoader<T, E>: NSObject where E: DataLoaderEngine<T> {
  deinit {
    NSLog("deinit: \(type(of: self))")
  }
  
  public weak var delegate: DataLoaderDelegate?

  let disposeBag = DisposeBag()
  var disposable: Disposable? = nil
  
  var error: Error? = nil
  
  private(set) public var rowsLoading = false
  private(set) public var rowsLoaded = false  
  private(set) public var mightHaveMore = true
  
  var filters: [Filter] = []
  
  fileprivate var rows: [T] = []
  public var isEmpty: Bool { return rows.count == 0 }
  public var newRowsPosition: NewRowsPosition = .beginning
  public var searchFilter: ((T) -> Bool)? = nil
  public var totalRows: Int { return rows.count }
  
  open var rowsToDisplay: [T] {
    if let isIncluded = searchFilter {
      return rows.filter(isIncluded)
    } else {
      return rows
    }
  }

  public var searchQueryString: String? = nil
  public var searchLoadType: DataLoadType = .clearAndReplace
  
  let notificationLoadTypeKey = "loadType"
  let notificationEditsKey = "edits"

  var notificationNamePrefix: String {
    return "co.bukapp.CollectionLoader.\(type(of: self))"
  }
  
  func notificationNameForAction(_ action: DataLoaderAction) -> String {
    return "\(notificationNamePrefix)\(action.rawValue)"
  }
  
  public var dataLoaderEngine: E!
  var cancellationToken: Operation?
  
  // MARK: - Initialize
  required public init(dataLoaderEngine: E) {
    super.init()
    
    self.dataLoaderEngine = dataLoaderEngine
    self.mightHaveMore = dataLoaderEngine.paginate
  }
  
  public func preSetRows(_ rows: [T]) {
    self.rows = rows
    self.rowsLoaded = true
  }
  
  // MARK: - CRUD
  open func registerForCRUDNotificationsWithClassName(_ className: String, senderObject: AnyObject? = nil) {
    disposable?.dispose()
    disposable = NotificationCenter.default.registerForCRUDNotification(className, senderObject: senderObject)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        Utils.performOnMainThread() {
          self?.handleCRUDNotification(notification)
        }
      })
  }
  
  open func handleCRUDNotification(_ notification: Notification) {
    if let object = notification.crudObject as? T {
    
      NSLog("dataLoader received notification: \(notification.crudNotificationType) \(object)")
      
      switch notification.crudNotificationType {
      case .create:
        self.addNewRow(object)
      case .update:
        self.updateRowForObject(object)
      case .delete:
        self.removeRowForObject(object)
      }
    }
  }

  // MARK: - Get Data
  public func searchByString(_ string: String?) {
    searchQueryString = string
    loadRows(loadType: searchLoadType)
  }
  
  fileprivate func clear() {
    rows = []
    rowsLoaded = false
    mightHaveMore = dataLoaderEngine.paginate
    delegate?.dataLoaderDidClearRows(self)
  }
  
  @discardableResult
  public func loadRows(loadType: DataLoadType) -> Promise<[T]>? {
    if rowsLoading && loadType != .clearAndReplace {
      return nil
    }
    
    if loadType == .clearAndReplace {
      clear()
    }

    error = nil
    rowsLoading = true
    
    delegate?.dataLoader(self, didStartLoadingRowsWithLoadType: loadType)
    
    return fetchData(forLoadType: loadType)
  }
  
  open func fetchData(forLoadType loadType: DataLoadType) -> Promise<[T]> {
    var updateTimes: [T:Date] = [:]
    for row in rows {
      if let updatedAt = row.updatedAt {
        updateTimes[row] = updatedAt
      }
    }
    
    cancellationToken?.cancel()
    let thisCancellationToken = Operation()
    cancellationToken = thisCancellationToken
        
    NSLog("Will execute: \(loadType); queryString: \(String(describing: searchQueryString))")
    return dataLoaderEngine.promise(forLoadType: loadType, queryString: searchQueryString, filters: filters).always {
      if !thisCancellationToken.isCancelled {
        NSLog("Got results for \(loadType); queryString: \(String(describing: self.searchQueryString))")

        self.rowsLoading = false
        
        NotificationCenter.default.post(
          name: Notification.Name(rawValue: self.notificationNameForAction(.ResultsReceived)),
          object: self,
          userInfo: self.userInfo(loadType: loadType))
      }
    }.then { results in
      if thisCancellationToken.isCancelled {
        return Promise(error: NSError.cancelledError())
      }

      var results = results
      //      for result in results {
      //        NSLog("\(result.objectId)")
      //      }
      
      let totalResults = results.count
      if let queryLimit = self.dataLoaderEngine.queryLimit, totalResults >= queryLimit && self.dataLoaderEngine.paginate {
        self.mightHaveMore = true
      } else {
        self.mightHaveMore = false
      }
      
      return Promise<[T]>() { (fulfill, reject) in
        // Sort/filter as necessary but do it in the background
        DispatchQueue.global(qos: .background).async {
          if let fn = self.dataLoaderEngine.filterFunction {
            results = results.filter(fn)
          }
          
          if let fn = self.dataLoaderEngine.sortFunction {
            results = results.sorted(by: fn)
          }
          
          fulfill(results)
        }
      }.then { (results: [T]) -> Promise<[T]> in
        self.handleResults(results, loadType: loadType, updateTimes: updateTimes)
        return Promise(value: results)
      }
    }.catch { error in
      self.delegate?.dataLoader(self, didCatchLoadingError: error)
      NSLog("error: \(error)")
    }
  }

  fileprivate func handleResults(_ queryResults: [T], loadType: DataLoadType, updateTimes: [T:Date]) {
    // Process the results
    var results = queryResults

    var edits: [Edit<T>] = []
    let originalRows: [T] = rowsToDisplay

    if !isEmpty && loadType == .newRows {
      // Adds/Updates
      let resultsToAdd = newRowsPosition == .end ? results : results.reversed()
      for result in resultsToAdd {
        if !rows.contains(result) {
          // Inserts the row, but won't update the UI
          switch newRowsPosition {
          case .beginning:
            rows.insert(result, at: 0)
          case .end:
            rows.append(result)
          }
        } else {
          if updateTimes[result] != result.updatedAt {
            if let index = rows.index(of: result) {
              updateRowAtIndex(index, withObject: result)
              edits.append(Edit(.substitution, value: result, destination: index))
            }
          }
        }
      }
    } else {
      if loadType == .more {
        for result in results {
          if !rows.contains(result) {
            rows.append(result)
          }
        }
      } else {
        if !isEmpty && loadType == .replace {
          for i in 0..<results.count {
            let newRow = results[i]
            if let existingIndex = rows.index(of: newRow) {
              if existingIndex == i {
                if updateTimes[newRow] != newRow.updatedAt {
                  edits.append(Edit(.substitution, value: newRow, destination: i))
                }
              }
            }
          }
        }
        
        rows = results
      }
    }
    
    // Optional post-processing
    rowsLoaded = true
    edits = edits + Changeset.edits(from: originalRows, to: rowsToDisplay)
    updateUI(forEdits: edits, loadType: loadType)
  }

  func sortRows(_ isOrderedBefore: (T, T) -> Bool) {
    rows = rows.sorted(by: isOrderedBefore)
  }

  
  // MARK: - Manipulating data
  func replaceRows(_ rows: [T]) {
    let edits: [Edit<T>] = Changeset.edits(from: self.rows, to: rows)
    self.rows = rows

    rowsLoaded = true
    
    updateUI(forEdits: edits, loadType: .replace)
  }
  
  public func addNewRow(_ object: T) {
    switch newRowsPosition {
    case .beginning:
      insertRow(object, atIndex: 0)
    case .end:
      appendRow(object)
    }    
  }
  
  func insertRow(_ object: T, atIndex index: Int) {
    if !rows.contains(object) {
      rows.insert(object, at: index)
      
      delegate?.dataLoader(self, didInsertRowAtIndex: index)
    }
  }
  
  func appendRow(_ object: T) {
    insertRow(object, atIndex: rows.count)
  }
  
  public func removeRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      removeRowAtIndex(index)
    }
  }

  @discardableResult
  func removeRowAtIndex(_ index: Int) -> T? {
    let object = rows.remove(at: index)
    delegate?.dataLoader(self, didRemoveRowAtIndex: index)
    
    return object
  }
  
  public func updateRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      updateRowAtIndex(index, withObject: object)
    }
  }
    
  func updateRowAtIndex(_ index: Int, withObject object: T) {
    rows[index] = object
    
    delegate?.dataLoader(self, didUpdateRowAtIndex: index)
  }
  
  
  // MARK: - Notifications
  func userInfo(edits: [Edit<T>]? = nil, loadType: DataLoadType) -> [AnyHashable: Any] {
    var userInfo: [AnyHashable: Any] = [
      notificationLoadTypeKey: loadType.rawValue,
    ]
    
    if let edits = edits {
      userInfo[notificationEditsKey] = edits
    }
    
    return userInfo
  }
  
  func postDidFinishLoadingNotification(forEdits edits: [Edit<T>]?, loadType: DataLoadType) {
    NotificationCenter.default.post(
      name: Notification.Name(rawValue: notificationNameForAction(.FinishedLoading)),
      object: self,
      userInfo: userInfo(edits: edits, loadType: loadType))
  }
  
  func observerForAction(_ action: DataLoaderAction) -> Observable<Notification> {
    let observer = NotificationCenter.default.rx.notification(Notification.Name(rawValue: notificationNameForAction(action)), object: self)

    if action == .FinishedLoading && rowsLoaded {
      let notification = Notification(
        name: Notification.Name(rawValue: notificationNameForAction(.FinishedLoading)),
        object: self,
        userInfo: userInfo(edits: Changeset.edits(from: [], to: rows), loadType: .initial))

      return observer.startWith(notification)
    } else {
      return observer
    }
  }
  
  public func editsFromNotification(_ notification: Notification) -> [Edit<T>]? {
    return notification.userInfo?[notificationEditsKey] as? [Edit<T>]
  }
  
  public func loadTypeFromNotification(_ notification: Notification) -> DataLoadType {
    return DataLoadType(rawValue: notification.userInfo![notificationLoadTypeKey] as! Int)!
  }

  
  // MARK: - UI Stuff
  open func updateUI(forEdits edits: [Edit<T>]?, loadType: DataLoadType) {
    postDidFinishLoadingNotification(forEdits: edits, loadType: loadType)
  }
}
