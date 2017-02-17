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

enum DataLoadType: Int {
  case initial, more, clearAndReplace, replace, newRows
}

enum DataLoaderAction: String {
  case ResultsReceived = "ResultsReceived", FinishedLoading = "FinishedLoading", CRUD = "CRUD"
}

enum NewRowsPosition {
  case beginning, end
}

class DataLoader<T: CollectionRow>: NSObject {
  deinit {
    NSLog("deinit: \(type(of: self))")
  }
  

  let disposeBag = DisposeBag()
  var disposable: Disposable? = nil
  var loaderViews: WeakArray<LoaderView> = []
  var scrollViews: WeakArray<UIScrollView> = []
  
  var error: Error? = nil
  
  var rowsLoading = false
  var rowsLoaded = false
  var mightHaveMore = true
  var queryLimit: Int { return 20 }
  var newRowsPosition: NewRowsPosition { return .end }
  
  var isEmpty: Bool { return rows.count == 0 }
  fileprivate(set) var rows: [T] = []
  
  let notificationActionKey = "actionType"
  let notificationLoadTypeKey = "loadType"
  let notificationTotalKey = "total"
  let notificationResultsKey = "results"
  let notificationCRUDTypeKey = "crudType"
  let notificationObjectKey = "object"
  let notificationIndexKey = "index"
  var notificationSenderObject: AnyObject? { return nil }

  
  var notificationNamePrefix: String {
    return "com.oinkist.CollectionLoader.\(type(of: self))"
  }
  
  func notificationNameForAction(_ action: DataLoaderAction) -> String {
    return "\(notificationNamePrefix)\(action.rawValue)"
  }
  
  var cancellationToken: Operation?
  
  
  var filterFunction: ((T) -> Bool)? = nil
  var sortFunction: ((T, T) -> Bool)? = nil
  
  // MARK: - Initialize
  required override init() {
    super.init()
  }
  
  init(rows: [T]?) {
    if let rows = rows {
      self.rows = rows
      rowsLoaded = true
    }
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
  
  func task(forLoadType loadType: DataLoadType) -> Task<NSArray> {
    return Task<NSArray>([] as NSArray)
  }
  
  @discardableResult
  func loadRows(loadType: DataLoadType) -> Task<NSArray>? {
    if rowsLoading && loadType != .clearAndReplace {
      return nil
    }
    
    error = nil
    
    if loadType == .clearAndReplace {
      clear()
      refreshScrollViews()
    }
    
    switch loadType {
    case .more, .newRows:
      // Don't show spinner if doing infinite scroll load
      // or refreshing for new rows
      break
    default:
      if loadType == .replace && rows.count > 0 {
        // No spinner here either
      } else {
        for loaderView in loaderViews {
          loaderView.showSpinner()
        }
      }
    }
    
    rowsLoading = true
    
    return runTask(forLoadType: loadType)
  }
  
  func runTask(forLoadType loadType: DataLoadType) -> Task<NSArray> {
    var updateTimes: [String:Date] = [:]
    for row in rows {
      if let id = row.objectId, let updatedAt = row.updatedAt {
        updateTimes[id] = updatedAt
      }
    }
    
    cancellationToken?.cancel()
    let thisCancellationToken = Operation()
    cancellationToken = thisCancellationToken
    
    return self.task(forLoadType: loadType).continueWithTask(Executor.mainThread, continuation: { task in
      if thisCancellationToken.isCancelled {
        return task
      } else if let error = task.error as? NSError {
        NSLog("error: \(task.error)")
        
        self.error = error
        self.rowsLoading = false
        
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
    
    var newRows: [T]? = nil
  
    var results = queryResults
    
    // Sort/filter as necessary
    if let fn = sortFunction {
      results = results.sorted(by: fn)
    }

    if !isEmpty && loadType == .newRows {
      insertNewRows(results)
    } else {
      if loadType == .more {
        let completion: (Bool) -> Void = { completed in
          for scrollView in self.scrollViews {
            scrollView.finishInfiniteScroll()
          }
        }
        
        let addRows = {
          for result in results {
            self.appendRow(result)
          }
        }
        
        for scrollView in self.scrollViews {
          if let indicatorView = scrollView.infiniteScrollIndicatorView {
            scrollView.sendSubview(toBack: indicatorView)
          }
          
          if let collectionView = scrollView as? UICollectionView {
            collectionView.performBatchUpdates({
              addRows()
            }, completion: completion)
          } else if let tableView = scrollView as? UITableView {
            tableView.performBatchUpdates({
              addRows()
            }, completion: completion)
          }
        }
      } else if !isEmpty && loadType == .replace && scrollViews.filter({ $0 != nil }).count > 0 {
        var updateTimes: [String:Date] = [:]
        for row in rows {
          if let id = row.objectId, let updatedAt = row.updatedAt {
            updateTimes[id] = updatedAt
          }
        }
        
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
              if let id = newRow.objectId {
                if updateTimes[id] != newRow.updatedAt {
                  updateRowForObject(newRow)
                }
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
      
      mightHaveMore = totalResults == queryLimit
    }

    // Optional post-processing
    processNewResults(newRows)

    rowsLoaded = true
    updateUIForNewRows(newRows, loadType: loadType)
  }

  func insertNewRows(_ results: [T]) {
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
          insertRow(result, atIndex: 0)
        case .end:
          appendRow(result)
        }
      } else if let id = result.objectId {
        if updateTimes[id] != result.updatedAt {
          updateRowForObject(result)
        }
      }
    }
  }
  
  func processNewResults(_ results: [T]?) {
    
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
      // NSLog("adding row at \(index): \(object)")
    }
  }
  
  func appendRow(_ object: T) {
    insertRow(object, atIndex: rows.count)
  }
  
  @discardableResult
  func removeRowAtIndex(_ index: Int, updateUI: Bool = true) -> T? {
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
  func registerLoaderView(_ loaderView: LoaderView) {
    loaderViews = loaderViews.filter { $0 != nil }
    if !loaderViews.contains(loaderView) {
      loaderViews.append(loaderView)
    }

    if rowsLoaded {
      loaderView.hideSpinner()
      checkEmpty()
    } else if rowsLoading {
      loaderView.showSpinner()
    } else {
      loaderView.isHidden = true
    }
  }
  
  func registerScrollView(_ scrollView: UIScrollView) {
    scrollViews = scrollViews.filter { $0 != nil }
    if !scrollViews.contains(scrollView) {
      scrollViews.append(scrollView)
    }
    
    scrollView.alwaysBounceVertical = true
  }
  
  func updateUIForCRUDCompletion(forCrudType crudType: CRUDType, object: T, atIndex index: Int, inSection section: Int) -> ((Bool) -> Void) {
    return { complete in
      self.checkEmpty()
      
      if self.isEmpty {
        self.refreshScrollViews()
      }
      
      self.postCrudNotification(crudType, object: object, atIndex: index, inSection: section)
    }
    
  }
  
  func updateUIForCRUD(_ crudType: CRUDType, object: T, atIndex index: Int, inSection section: Int = 0) {
    let completion: (Bool) -> Void = updateUIForCRUDCompletion(forCrudType: crudType, object: object, atIndex: index, inSection: section)

    switch crudType {
    case .Create:
      for scrollView in scrollViews {
        if let collectionView = scrollView as? UICollectionView {
          collectionView.performBatchUpdates({
            collectionView.insertItems(at: [IndexPath(item: index, section: section)])
          }, completion: completion)
        } else if let tableView = scrollView as? UITableView {
          tableView.performBatchUpdates({
            tableView.insertRows(at: [IndexPath(row: index, section: section)], with: .fade)
          }, completion: completion)
        }
      }
    case .Update:
      for scrollView in scrollViews {
        if let collectionView = scrollView as? UICollectionView {
          collectionView.performBatchUpdates({
            collectionView.reloadItems(at: [IndexPath(item: index, section: section)])
          }, completion: completion)
        } else if let tableView = scrollView as? UITableView {
          tableView.performBatchUpdates({
            tableView.reloadRows(at: [IndexPath(row: index, section: section)], with: .none)
          }, completion: completion)
        }
      }
    case .Delete:
      for scrollView in scrollViews {
        if let collectionView = scrollView as? UICollectionView {
          collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [IndexPath(item: index, section: section)])
          }, completion: completion)
        } else if let tableView = scrollView as? UITableView {
          tableView.performBatchUpdates({
            tableView.deleteRows(at: [IndexPath(row: index, section: section)], with: .fade)
          }, completion: completion)
        }
      }
    }
  }
  
  func updateUIForNewRows(_ newRows: [T]?, loadType: DataLoadType) {
    for loaderView in loaderViews {
      loaderView.hideSpinner()
    }

    // If we didn't pass the new rows here, that means
    // we incrementally updated the UI so no need to refresh
    if newRows != nil {
      refreshScrollViews()
    }
    
    checkEmpty()
    postDidFinishLoadingNotificationForResults(newRows, loadType: loadType)
  }

  func checkEmpty() {
    for loaderView in loaderViews {
      if isEmpty {
        loaderView.showEmptyView()
      } else {
        loaderView.isHidden = true
      }
    }
  }
  
  func refreshScrollViews() {
    for scrollView in scrollViews {
      refreshScrollView(scrollView)
    }
  }
  
  func refreshScrollView(_ scrollView: UIScrollView) {
    if let collectionView = scrollView as? UICollectionView {
      // collectionView.reloadSections(IndexSet(integersIn: 0..<collectionView.numberOfSections))
      collectionView.reloadData()
    } else if let tableView = scrollView as? UITableView {
      tableView.reloadData()
    }
  }
}
