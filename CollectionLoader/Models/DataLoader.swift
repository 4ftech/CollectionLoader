//
//  DataLoader.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//


import Foundation
import RxSwift
import BoltsSwift
import UIScrollView_InfiniteScroll

public enum DataLoadType: Int {
  case initial, more, clearAndReplace, replace, newRows
}

enum DataLoaderAction: String {
  case ResultsReceived = "ResultsReceived", FinishedLoading = "FinishedLoading", CRUD = "CRUD"
}

enum NewRowsPosition {
  case beginning, end
}

public protocol DataLoaderEngine {
  func task(forLoadType loadType: DataLoadType, currentRowCount: Int) -> Task<NSArray>
}

class DataLoader<T: CollectionRow>: NSObject {
  deinit {
    NSLog("deinit: \(type(of: self))")
  }
  

  let disposeBag = DisposeBag()
  var disposable: Disposable? = nil
  
  var error: Error? = nil
  
  var rowsLoading = false
  var rowsLoaded = false
  var mightHaveMore = true
  var queryLimit: Int = 20
  var newRowsPosition: NewRowsPosition = .beginning
  
  var rows: [T] = []
  var isEmpty: Bool { return rows.count == 0 }
  var rowsToDisplay: [T] {
    return rows
  }

  let notificationActionKey = "actionType"
  let notificationLoadTypeKey = "loadType"
  let notificationTotalKey = "total"
  let notificationResultsKey = "results"
  let notificationCRUDTypeKey = "crudType"
  let notificationObjectKey = "object"
  let notificationIndexKey = "index"
  var notificationSenderObject: AnyObject? = nil

  var notificationNamePrefix: String {
    return "com.oinkist.CollectionLoader.\(type(of: self))"
  }
  
  func notificationNameForAction(_ action: DataLoaderAction) -> String {
    return "\(notificationNamePrefix)\(action.rawValue)"
  }
  
  var cancellationToken: Operation?
  var dataLoaderEngine: DataLoaderEngine!
  
  var filterFunction: ((T) -> Bool)? = nil
  var sortFunction: ((T, T) -> Bool)? = nil
  
  // MARK: - Initialize
  required override init() {
    super.init()
  }
  
  init(dataLoaderEngine: DataLoaderEngine) {
    self.dataLoaderEngine = dataLoaderEngine
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
    
    // NSLog("dataLoader (\(self?.notificationNamePrefix)) received notification: \(notification.crudNotificationType) \(object)")
    
    switch notification.crudNotificationType {
    case .Create:
      switch newRowsPosition {
      case .beginning:
        insertRow(object, atIndex: 0)
      case .end:
        appendRow(object)
      }
    case .Update:
      updateRowForObject(object)
    case .Delete:
      removeRowForObject(object)
    }
  }

  // MARK: - Data
  func clear() {
    rows = []
    rowsLoaded = false
    mightHaveMore = true
  }
  
  @discardableResult
  func loadRows(loadType: DataLoadType) -> Task<NSArray>? {
    if rowsLoading && loadType != .clearAndReplace {
      return nil
    }
    
    if loadType == .clearAndReplace {
      clear()
    }

    error = nil
    rowsLoading = true
    
    return runTask(forLoadType: loadType)
  }
  
  func runTask(forLoadType loadType: DataLoadType) -> Task<NSArray> {
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
    return dataLoaderEngine.task(forLoadType: loadType, currentRowCount: rows.count).continueWithTask(Executor.mainThread, continuation: { task in
      self.rowsLoading = false
      
      if thisCancellationToken.isCancelled {
        return task
      } else if let error = task.error as? NSError {
        NSLog("error: \(task.error)")
        
        self.error = error

        return task
      } else {
        var results: [T] = (task.result as? [T]) ?? []
        
        if let fn = self.filterFunction {
          results = results.filter(fn)
        }

        NotificationCenter.default.post(
          name: Notification.Name(rawValue: self.notificationNameForAction(.ResultsReceived)),
          object: self.notificationSenderObject,
          userInfo: self.userInfoForResults(results, loadType: loadType))
        
        self.handleResults(results, loadType: loadType)
        
        return Task<NSArray>(results as NSArray)
      }
    })
  }

  fileprivate func handleResults(_ queryResults: [T], loadType: DataLoadType) {
    // Process the results
    let totalResults = queryResults.count
    
    var results: [T] = queryResults
    
    // Sort/filter as necessary
    if let fn = sortFunction {
      results = results.sorted(by: fn)
    }

    if !isEmpty && loadType == .newRows {
      var updateTimes: [String:Date] = [:]
      for row in rows {
        if let id = row.objectId, let updatedAt = row.updatedAt {
          updateTimes[id] = updatedAt
        }
      }
      
      // Adds/Updates
      let resultsToAdd = newRowsPosition == .end ? results : results.reversed()
      for result in resultsToAdd {
        if !rows.contains(result) {
          switch newRowsPosition {
          case .beginning:
            rows.insert(result, at: 0)
          case .end:
            rows.append(result)
          }
        } else if let id = result.objectId {
          if updateTimes[id] != result.updatedAt {
            updateRowForObject(result)
          }
        }
      }
    } else {
      if loadType == .more {
        rows = rows + results
      } else {
        rows = results
      }
      
      mightHaveMore = totalResults == queryLimit
    }

    // Optional post-processing
    rowsLoaded = true
    updateUIForNewRows(results, loadType: loadType)
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
      
      updateUIForCRUD(.Create, object: object, atIndex: index)
    }
  }
  
  func appendRow(_ object: T) {
    insertRow(object, atIndex: rows.count)
  }
  
  @discardableResult
  func removeRowAtIndex(_ index: Int) -> T? {
    let object = rows.remove(at: index)
    
    updateUIForCRUD(.Delete, object: object, atIndex: index)
    
    // NSLog("removing row at \(index): \(object)")
    
    return object
  }
  
  func removeRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      removeRowAtIndex(index)
    }
  }
  
  func updateRowForObject(_ object: T) {
    if let index = rows.index(of: object) {
      rows[index] = object

      updateUIForCRUD(.Update, object: object, atIndex: index)
    }
  }
  
  // MARK: - Notifications
  func userInfoForResults(_ results: [T]?, loadType: DataLoadType) -> [AnyHashable: Any] {
    var userInfo: [AnyHashable: Any] = [
      notificationActionKey: DataLoaderAction.FinishedLoading.rawValue,
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
      userInfo: userInfoForResults(results, loadType: loadType))
  }
  
  func postCrudNotification(_ crudType: CRUDType, object: T, atIndex index: Int, inSection section: Int = 0) {
    NotificationCenter.default.post(
      name: Notification.Name(rawValue: notificationNameForAction(.CRUD)),
      object: notificationSenderObject,
      userInfo: [
        notificationActionKey: DataLoaderAction.CRUD.rawValue,
        notificationCRUDTypeKey: crudType.rawValue,
        notificationObjectKey: object,
        notificationIndexKey: index
      ])
  }
  
  func observerForAction(_ action: DataLoaderAction) -> Observable<Notification> {
    let observer = NotificationCenter.default.rx.notification(Notification.Name(rawValue: notificationNameForAction(action)), object: notificationSenderObject)
    
    if action == .FinishedLoading && rowsLoaded {
      let notification = Notification(
        name: Notification.Name(rawValue: notificationNameForAction(.FinishedLoading)),
        object: notificationSenderObject,
        userInfo: userInfoForResults(rows, loadType: .initial))

      return observer.startWith(notification)
    } else {
      return observer
    }
  }
  
  func subscribeToAllDataUpdates(_ disposeBag: DisposeBag, subscriber: @escaping (Notification) -> Void) {
    let actionTypes: [DataLoaderAction] = [.FinishedLoading, .CRUD]
    for actionType in actionTypes {
      observerForAction(actionType).subscribe(onNext: subscriber).addDisposableTo(disposeBag)
    }
  }
  
  func resultsFromNotification(_ notification: Notification) -> [T]? {
    return notification.userInfo?[notificationResultsKey] as? [T]
  }
  
  func rowUpdateInfoFromNotification(_ notification: Notification) -> (CRUDType, T, Int) {
    let userInfo = notification.userInfo!
    let type = CRUDType(rawValue: userInfo[notificationCRUDTypeKey] as! String)!
    let object = userInfo[notificationObjectKey] as! T
    let index = userInfo[notificationIndexKey] as! Int
    
    return (type, object, index)
  }
  
  func actionTypeFromNotification(_ notification: Notification) -> DataLoaderAction {
    return DataLoaderAction(rawValue: notification.userInfo![notificationActionKey] as! String)!
  }

  func loadTypeFromNotification(_ notification: Notification) -> DataLoadType {
    return DataLoadType(rawValue: notification.userInfo![notificationLoadTypeKey] as! Int)!
  }

  
  func resultCountFromNotification(_ notification: Notification) -> Int {
    return notification.userInfo![notificationTotalKey] as! Int
  }

  
  // MARK: - UI Stuff
  func updateUIForCRUD(_ crudType: CRUDType, object: T, atIndex index: Int, inSection section: Int = 0) {
    postCrudNotification(crudType, object: object, atIndex: index, inSection: section)
  }
  
  func updateUIForNewRows(_ newRows: [T]?, loadType: DataLoadType) {
    postDidFinishLoadingNotificationForResults(newRows, loadType: loadType)
  }
}
