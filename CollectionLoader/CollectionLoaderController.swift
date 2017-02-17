//
//  CollectionLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import Spring
import RxSwift
import UIScrollView_InfiniteScroll

public enum CollectionViewType {
  case table, collection
}

public class CollectionLoaderController<T: CollectionRow>: UIViewController, CollectionSearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
  let singleLineTableCellIdentifier = "singleLineIconCell"
  let twoLineTableCellIdentifier = "twoLineIconCell"
  let threeLineTableCellIdentifier = "threeLineIconCell"

  public var collectionViewType: CollectionViewType = .table
  public var emptyViewContent: EmptyViewContent?
  
  var container: SpringView!
  var scrollView: UIScrollView!

  var loaderView: LoaderView!
  var pullToRefresh: Bool = true
  var refreshControl: UIRefreshControl?
  
  // Search
  var allowSearch: Bool = false
  var searchBar: CollectionSearchBar?
  
  var searchFilter: (String) -> ((T) -> Bool) = { queryString in
    return { object in
      return object.name?.contains(queryString) ?? false
    }
  }
  
  // Insets
  var topInset: CGFloat {
    var topInset: CGFloat = 0
    
    if allowSearch {
      topInset = topInset + Utils.searchBarHeight
    }
    
    return topInset
  }
  
  // DATA
  var collectionInitialized = false
  var dataLoader: DataLoader<T>!
  var disposeBag: DisposeBag = DisposeBag()

  var refreshOnAppear: DataLoadType? = .newRows
  
  // MARK: - Initialize
  required public init(dataLoaderEngine: DataLoaderEngine) {
    super.init(nibName: nil, bundle: nil)
    
    self.dataLoader = DataLoader<T>(dataLoaderEngine: dataLoaderEngine)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Controller
  override public func viewDidLoad() {
    super.viewDidLoad()

    edgesForExtendedLayout = []
    extendedLayoutIncludesOpaqueBars = false
    
    // Add Container and ScrollView
    container = SpringView()
    Utils.fillContainer(view, withView: container)
    
    switch collectionViewType {
    case .collection:
      let collectionView = UICollectionView()
      
      scrollView = collectionView
      break
    case .table:
      let tableView = UITableView()
      tableView.tableFooterView = UIView(frame: CGRect.zero)
      tableView.delegate = self
      tableView.dataSource = self
      
      scrollView = tableView
      break
    }

    Utils.fillContainer(container, withView: scrollView)
    
    // Loader
    loaderView = LoaderView.newInstance(content: emptyViewContent)
    Utils.fillContainer(view, withView: loaderView)
    
    // Table
    container.autohide = true
    container.autostart = false

    // ScrollView
    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    
    scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    
    if pullToRefresh {
      refreshControl = UIRefreshControl()
      refreshControl?.addTarget(self, action: #selector(didPullToRefresh(refreshControl:)), for: .valueChanged)
      scrollView.refreshControl = refreshControl
    }
    
    // Register cells
    registerCells()
    
    // Subscribe to data loader notifications
    subscribeToDataLoaderNotifications()
    
    // Search
    if allowSearch {
      searchBar = CollectionSearchBar.newInstance()
      searchBar?.delegate = self
      searchBar?.isHidden = dataLoader.isEmpty
      Utils.addView(searchBar!, toContainer: container, onEdge: .top)
      
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardDidShow(_:)), name: Notification.Name.UIKeyboardDidShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // OK GO
    if !dataLoader.rowsLoaded && !dataLoader.rowsLoading {
      loadRows(loadType: .initial)
    } else if dataLoader.rowsLoaded {
      loaderView.hideSpinner()
      didUpdateRowDataUI()
    } else if dataLoader.rowsLoading {
      loaderView.showSpinner()
    } else {
      loaderView.isHidden = true
    }
  }
  
  func searchKeyboardDidShow(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
          self.scrollView.contentInset.bottom = keyboardSize.height
        }, completion: nil)
      }
    }
  }
  
  func searchKeyboardWillHide(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      
      UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
        self.scrollView.contentInset.bottom = 0
      }, completion: nil)
    }
  }
  
  func didPullToRefresh(refreshControl: UIRefreshControl) {
    loadRows(loadType: .newRows)
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let loadType = refreshOnAppear, dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized {
      loadRows(loadType: loadType)
    }
  }
  
  func registerCells() {
    switch collectionViewType {
    case .collection:
      break
    case .table:
      let tableView = scrollView as! UITableView
      
      let bundle = Bundle(identifier: "com.oinkist.CollectionLoader")
      tableView.register(UINib(nibName: "SingleLineIconCell", bundle: bundle), forCellReuseIdentifier: singleLineTableCellIdentifier)
      tableView.register(UINib(nibName: "TwoLineIconCell", bundle: bundle), forCellReuseIdentifier: twoLineTableCellIdentifier)
      tableView.register(UINib(nibName: "ThreeLineIconCell", bundle: bundle), forCellReuseIdentifier: threeLineTableCellIdentifier)
    }
  }


  // MARK: - Querying
  func loadRows(loadType: DataLoadType) {
    if dataLoader.rowsLoading && loadType != .clearAndReplace {
      return
    }
    
    dataLoader.loadRows(loadType: loadType)
    
    // If .clearAndReplace, dataLoader.loadRows already cleared all rows
    if loadType == .clearAndReplace {
      refreshScrollView()
    }

    switch loadType {
    case .more, .newRows:
      // Don't show spinner if doing infinite scroll load
      // or refreshing for new rows
      break
    default:
      if loadType == .replace && dataLoader.rowsToDisplay.count > 0 {
        // No spinner here either
      } else {
        loaderView.showSpinner()
      }
    }
  }
  
  func subscribeToDataLoaderNotifications() {
    dataLoader.observerForAction(.ResultsReceived)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        Utils.performOnMainThread() {
          self?.handleResultsReceivedNotification(notification)
        }
      }).addDisposableTo(disposeBag)
    
    dataLoader.observerForAction(.FinishedLoading)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        Utils.performOnMainThread() {
          self?.handleDidFinishLoadingRowsNotification(notification)
        }
      }).addDisposableTo(disposeBag)
    
    dataLoader.observerForAction(.CRUD)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        Utils.performOnMainThread() {
          self?.handleCrudNotification(notification)
        }
      }).addDisposableTo(disposeBag)
  }
  
  func handleResultsReceivedNotification(_ notification: Notification) {
    let loadType = dataLoader.loadTypeFromNotification(notification)
    //    let results = dataLoader.resultsFromNotification(notification)

    if loadType != .more {
      refreshControl?.endRefreshing()
    }
    
  }
  
  func handleCrudNotification(_ notification: Notification) {
    let (type, object, index) = dataLoader.rowUpdateInfoFromNotification(notification)
    let completion: (Bool) -> Void = { complete in
      if self.dataLoader.isEmpty {
        self.refreshScrollView()
      }
      
      switch type {
      case .Create:
        self.didInsertRow(object, atIndex: index)
      case .Update:
        self.didUpdateRow(object, atIndex: index)
      case .Delete:
        self.didRemoveRow(object, atIndex: index)
      }
      
      self.didUpdateRowDataUI()
    }
    
    switch type {
    case .Create:
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
        }, completion: completion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchUpdates({
          tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }, completion: completion)
      }
    case .Update:
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }, completion: completion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchUpdates({
          tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }, completion: completion)
      }
    case .Delete:
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }, completion: completion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchUpdates({
          tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }, completion: completion)
      }
    }
  }
  
  func handleDidFinishLoadingRowsNotification(_ notification: Notification) {
    let loadType = dataLoader.loadTypeFromNotification(notification)
    let results = dataLoader.resultsFromNotification(notification)

    loaderView.hideSpinner()
    
    if loadType == .more || loadType == .newRows {
      // Don't finish infinite scroll until insert animations are done
      let completion: (Bool) -> Void = { completed in
        if loadType == .more {
          self.scrollView.finishInfiniteScroll()
        }
      }
      
      if let indicatorView = scrollView.infiniteScrollIndicatorView, loadType == .more {
        // So that the new rows will fade in front of the indicator
        scrollView.sendSubview(toBack: indicatorView)
      }
      
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          if let results = results {
            for result in results {
              if let index = self.dataLoader.rowsToDisplay.index(of: result) {
                collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
              }
            }
          }
        }, completion: completion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchUpdates({
          if let results = results {
            for result in results {
              if let index = self.dataLoader.rowsToDisplay.index(of: result) {
                tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
              }
            }
          }
        }, completion: completion)
      }
    } else if results != nil {
      refreshScrollView()
    }

    if !collectionInitialized {
      initialDisplay()
      collectionInitialized = true
    }
    
    if dataLoader.mightHaveMore {
      scrollView.addInfiniteScroll() { [weak self] scrollView in
        self?.loadRows(loadType: .more)
      }
    } else {
      scrollView.removeInfiniteScroll()
    }
    
    didUpdateRowDataUI()
  }
  
  // MARK: - Manipulating data
  func didRemoveRow(_ object: T, atIndex index: Int) {
    
  }

  func didUpdateRow(_ object: T, atIndex index: Int) {
    
  }
  
  func didInsertRow(_ object: T, atIndex index: Int) {
    
  }

  func didUpdateRowDataUI() {
    searchBar?.isHidden = dataLoader.isEmpty
    checkEmpty()
  }

  // MARK: - Displaying results
  func initialDisplay() {
    container.animation = "fadeIn"
    container.duration = 1.0
    container.animate()
  }
  
  func checkEmpty() {
    if dataLoader.isEmpty {
      loaderView.showEmptyView()
    } else {
      loaderView.isHidden = true
    }
  }
  
  func refreshScrollView() {
    switch collectionViewType {
    case .collection:
      let collectionView = scrollView as! UICollectionView
      collectionView.reloadData()
      break
    case .table:
      let tableView = scrollView as! UITableView
      tableView.reloadData()
      break
    }
  }
  
  // MARK: - CollectionSearchBarDelegate
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    refreshScrollView()
  }

  // MARK: - UITableView
  public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]

    let cell = tableView.dequeueReusableCell(withIdentifier: singleLineTableCellIdentifier, for: indexPath) as! SingleLineIconCell
    cell.mainLabel.text = row.name
    
    return cell
  }
}
