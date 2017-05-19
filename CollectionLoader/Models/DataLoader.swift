//
//  DataLoader.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//


import Foundation
import RxSwift
import UIScrollView_InfiniteScroll
import PromiseKit
import DataSource

enum DataLoaderAction: String {
  case ResultsReceived = "ResultsReceived", FinishedLoading = "FinishedLoading", CRUD = "CRUD"
}

enum NewRowsPosition {
  case beginning, end
}

protocol DataLoaderDelegate: class {
  func didInsertRowAtIndex(_ index: Int)
  func didUpdateRowAtIndex(_ index: Int)
  func didRemoveRowAtIndex(_ index: Int)
  func didClearRows()
}

public class DataLoader<EngineType: DataLoaderEngine>: NSObject {
  public typealias T = EngineType.T
  
  deinit {
    NSLog("deinit: \(type(of: self))")
  }
  
  weak var delegate: DataLoaderDelegate?

  let disposeBag = DisposeBag()
  var disposable: Disposable? = nil
  
  var error: Error? = nil
  
  var rowsLoading = false
  var rowsLoaded = false
  var mightHaveMore = true
  var newRowsPosition: NewRowsPosition = .beginning
  
  fileprivate var rows: [T] = []
  var isEmpty: Bool { return rows.count == 0 }
  
  var searchQueryString: String? = nil

  public var rowsToDisplay: [T] {
    return rows
  }

  let notificationLoadTypeKey = "loadType"
  let notificationResultsKey = "results"
  var notificationSenderObject: AnyObject? = nil

  var notificationNamePrefix: String {
    return "co.bukapp.CollectionLoader.\(type(of: self))"
  }
  
  func notificationNameForAction(_ action: DataLoaderAction) -> String {
    return "\(notificationNamePrefix)\(action.rawValue)"
  }
  
  var cancellationToken: Operation?
  var dataLoaderEngine: EngineType!
  
  var filterFunction: ((T) -> Bool)? = nil
  var sortFunction: ((T, T) -> Bool)? = nil
  
  // MARK: - Initialize
  required override public init() {
    super.init()
    
  }
  
  convenience public init(dataLoaderEngine: EngineType) {
    self.init()
    
    self.dataLoaderEngine = dataLoaderEngine
    self.registerForCRUDNotificationsWithClassName(String(describing: T.self))
    
    self.mightHaveMore = dataLoaderEngine.paginate
  }
  
  // MARK: - CRUD
  func registerForCRUDNotificationsWithClassName(_ className: String, senderObject: T? = nil) {
    disposable?.dispose()
    disposable = NotificationCenter.default.registerForCRUDNotification(className, senderObject: senderObject as AnyObject?)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        Utils.performOnMainThread() {
          self?.handleCRUDNotification(notification)
        }
      })
  }
  
  func handleCRUDNotification(_ notification: Notification) {
    let object = notification.crudObject as! T
    
    NSLog("dataLoader received notification: \(notification.crudNotificationType) \(object)")
    
    switch notification.crudNotificationType {
    case .create:
      switch newRowsPosition {
      case .beginning:
        insertRow(object, atIndex: 0)
      case .end:
        appendRow(object)
      }
    case .update:
      if let index = rows.index(of: object) {
        updateRowAtIndex(index, withObject: object)
      }
    case .delete:
      if let index = rows.index(of: object) {
        removeRowAtIndex(index)
      }
    }
  }

  // MARK: - Get Data
  func searchByString(_ string: String?) {
    searchQueryString = string
    loadRows(loadType: .clearAndReplace)
  }
  
  fileprivate func clear() {
    rows = []
    rowsLoaded = false
    mightHaveMore = dataLoaderEngine.paginate
    delegate?.didClearRows()
  }
  
  @discardableResult
  func loadRows(loadType: DataLoadType) -> Promise<[T]>? {
    if rowsLoading && loadType != .clearAndReplace {
      return nil
    }
    
    if loadType == .clearAndReplace {
      clear()
    }

    error = nil
    rowsLoading = true
    
    return fetchData(forLoadType: loadType)
  }
  
  func fetchData(forLoadType loadType: DataLoadType) -> Promise<[T]> {
    var updateTimes: [T:Date] = [:]
    for row in rows {
      if let updatedAt = row.updatedAt {
        updateTimes[row] = updatedAt
      }
    }
    
    cancellationToken?.cancel()
    let thisCancellationToken = Operation()
    cancellationToken = thisCancellationToken
    
    NSLog("Will execute: \(loadType)")
    return dataLoaderEngine.promise(forLoadType: loadType, queryString: searchQueryString).always {
      if !thisCancellationToken.isCancelled {
        self.rowsLoading = false
        
        NotificationCenter.default.post(
          name: Notification.Name(rawValue: self.notificationNameForAction(.ResultsReceived)),
          object: self.notificationSenderObject,
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
      
      if let fn = self.filterFunction {
        results = results.filter(fn)
      }
      
      self.handleResults(results, loadType: loadType, updateTimes: updateTimes)
      
      return Promise(value: results)
    }
  }

  fileprivate func handleResults(_ queryResults: [T], loadType: DataLoadType, updateTimes: [T:Date]) {
    // Process the results
    let totalResults = queryResults.count
    
    var newRows: [T]? = nil
  
    var results = queryResults
    
    // Sort/filter as necessary
    if let fn = sortFunction {
      results = results.sorted(by: fn)
    }

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
            updateRowForObject(result)
          }
        }
      }
      
      newRows = results
    } else {
      if loadType == .more {
        rows = rows + results
        newRows = results
      } else if !isEmpty && loadType == .replace {
        let existingRows = rows
        for existingRow in existingRows {
          if !results.contains(existingRow) {
            removeRowForObject(existingRow)
          }
        }
        
        for i in 0..<results.count {
          let newRow = results[i]
          if let existingIndex = rows.index(of: newRow) {
            if existingIndex == i {
              if updateTimes[newRow] != newRow.updatedAt {
                updateRowForObject(newRow)
              }
              
              // Already exists in the row and is in the same position
              continue
            } else {
              removeRowAtIndex(existingIndex)
            }
          }
            
          insertRow(newRow, atIndex: i)
        }
      } else {
        rows = results
        newRows = results
      }
      
      mightHaveMore = totalResults == dataLoaderEngine.queryLimit && dataLoaderEngine.paginate
    }

    // Optional post-processing
    rowsLoaded = true
    updateUIForNewRows(newRows, loadType: loadType)
  }

  func sortRows(_ isOrderedBefore: (T, T) -> Bool) {
    rows = rows.sorted(by: isOrderedBefore)
  }

  
  // MARK: - Manipulating data
  func replaceRows(_ rows: [T]) {
    self.rows = rows

    rowsLoaded = true
    
    updateUIForNewRows(rows, loadType: .replace)
  }
  
  func insertRow(_ object: T, atIndex index: Int) {
    if !rows.contains(object) {
      rows.insert(object, at: index)
      
      delegate?.didInsertRowAtIndex(index)
    }
  }
  
  func appendRow(_ object: T) {
    insertRow(object, atIndex: rows.count)
  }
  
  @discardableResult
  func removeRowAtIndex(_ index: Int) -> T? {
    let object = rows.remove(at: index)
    delegate?.didRemoveRowAtIndex(index)
    
    return object
  }
  
  func removeRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      removeRowAtIndex(index)
    }
  }
  
  func updateRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      updateRowAtIndex(index, withObject: object)
    }
  }
    
  func updateRowAtIndex(_ index: Int, withObject object: T) {
    rows[index] = object
    
    delegate?.didUpdateRowAtIndex(index)
  }
  
  
  // MARK: - Notifications
  func userInfo(results: [T]? = nil, loadType: DataLoadType) -> [AnyHashable: Any] {
    var userInfo: [AnyHashable: Any] = [
      notificationLoadTypeKey: loadType.rawValue,
    ]
    
    if let results = results {
      userInfo[notificationResultsKey] = results
    }
    
    return userInfo
  }
  
  func postDidFinishLoadingNotificationForResults(_ results: [T]?, loadType: DataLoadType) {
    NotificationCenter.default.post(
      name: Notification.Name(rawValue: notificationNameForAction(.FinishedLoading)),
      object: notificationSenderObject,
      userInfo: userInfo(results: results, loadType: loadType))
  }
  
  func observerForAction(_ action: DataLoaderAction) -> Observable<Notification> {
    let observer = NotificationCenter.default.rx.notification(Notification.Name(rawValue: notificationNameForAction(action)), object: notificationSenderObject)
    
    if action == .FinishedLoading && rowsLoaded {
      let notification = Notification(
        name: Notification.Name(rawValue: notificationNameForAction(.FinishedLoading)),
        object: notificationSenderObject,
        userInfo: userInfo(results: rows, loadType: .initial))

      return observer.startWith(notification)
    } else {
      return observer
    }
  }
  
  func resultsFromNotification(_ notification: Notification) -> [T]? {
    return notification.userInfo?[notificationResultsKey] as? [T]
  }
  
  func loadTypeFromNotification(_ notification: Notification) -> DataLoadType {
    return DataLoadType(rawValue: notification.userInfo![notificationLoadTypeKey] as! Int)!
  }

  
  // MARK: - UI Stuff
  func updateUIForNewRows(_ newRows: [T]?, loadType: DataLoadType) {
    postDidFinishLoadingNotificationForResults(newRows, loadType: loadType)
  }
}
