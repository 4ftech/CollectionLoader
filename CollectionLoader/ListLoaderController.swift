//
//  ListLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import UIScrollView_InfiniteScroll

import DataSource

open class ListLoaderController<AdapterType: BaseListAdapter>: UIViewController, CollectionSearchBarDelegate, DataLoaderDelegate {
  let singleLineTableCellIdentifier = "singleLineIconCell"
  let twoLineTableCellIdentifier = "twoLineIconCell"
  let threeLineTableCellIdentifier = "threeLineIconCell"

  typealias m = LoaderView
  
  public var loaderView: LoaderView!
  public var listAdapter: AdapterType!
  
  public var pullToRefresh: Bool = false
  var refreshControl: UIRefreshControl?

  public var container: UIView!
  public var emptyViewContent: EmptyViewContent?
  public var scrollView: UIScrollView {
    return listAdapter.scrollView
  }  
  
  // Filters
  public var filters: [Filter] {
    get {
      return dataLoader.filters
    }
    set {
      dataLoader.filters = newValue
    }
  }
  
  public var isAnyFilterApplied: Bool {
    for filter in filters {
      if filter.isApplied {
        return true
      }
    }
    
    return false
  }
  
  public var filtersDescription: String? {
    let descriptions = filters.filter({ $0.isApplied && $0.filterDescription != nil && !$0.filterDescription!.isEmpty }).map({ $0.filterDescription! })
    if descriptions.count > 0 {
      return descriptions.joined(separator: ", ")
    }
    
    return nil
  }
  
  // Search
  public var allowSearch: Bool = false
  public var searchBar: CollectionSearchBar?
  
  // Insets
  open var scrollTopInset: CGFloat {
    var topInset: CGFloat = 0
    
    if let searchBar = searchBar, allowSearch {
      topInset = topInset + searchBar.frame.size.height
    }
    
    return topInset
  }
  
  open var topBarInset: CGFloat {
    var topInset: CGFloat = 0
    
    if let navController = navigationController, !navController.isNavigationBarHidden && extendedLayoutIncludesOpaqueBars && edgesForExtendedLayout.contains(.top) {
      topInset = topInset + Const.topBarHeight
    }
    
    return topInset
  }
  
  var scrollBottomInset: CGFloat?
  
  // DATA
  var collectionInitialized = false
  var disposeBag: DisposeBag = DisposeBag()

  public var dataLoader: DataLoader<AdapterType.EngineType> {
    return listAdapter.dataLoader
  }
  
  public var dataLoaderEngine: AdapterType.EngineType {
    return dataLoader.dataLoaderEngine
  }
  
  public var refreshOnAppear: DataLoadType? = nil  
  public var rowsLoading: Bool { return dataLoader.rowsLoading }
  public var rowsLoaded: Bool { return dataLoader.rowsLoaded }
  public var rows: [AdapterType.EngineType.T] { return dataLoader.rowsToDisplay }
  
  // MARK: - Initialize
  public init(listAdapter: AdapterType) {
    super.init(nibName: nil, bundle: nil)
    
    self.listAdapter = listAdapter
    self.listAdapter.viewController = self
    
    self.emptyViewContent = EmptyViewContent(message: "No results")

  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Controller
  override open func viewDidLoad() {
    super.viewDidLoad()

    NSLog("viewDidLoad for ListLoaderController")
    
    // Don't set delegate until view is loaded
    self.dataLoader.delegate = self
    
    //    edgesForExtendedLayout = []
    //    extendedLayoutIncludesOpaqueBars = false
    //    automaticallyAdjustsScrollViewInsets = true
    
    view.backgroundColor = UIColor.white
    
    // Search
    if allowSearch {
      if searchBar == nil {
        searchBar = CollectionSearchBar.newInstance()
      }
      
      searchBar?.delegate = self
      searchBar?.isHidden = false
      view.addView(
        searchBar!,
        onEdge: .top,
        edgeInsets: UIEdgeInsets(top: topBarInset, left: 0, bottom: 0, right: 0)
      )
    }
    
    // Add Container and ScrollView
    container = UIView(frame: view.frame)
    container.alpha = 0
    view.fill(withView: container)
    
    listAdapter.registerCells()
    scrollView.frame = container.frame
    container.fill(withView: scrollView)
    
    // Loader
    loaderView = LoaderView.newInstance(content: emptyViewContent)
    view.fill(
      withView: loaderView,
      edgeInsets: UIEdgeInsets(top: topBarInset + scrollTopInset, left: 0, bottom: 0, right: 0)
    )
    
    // ScrollView
    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    
    scrollView.contentInset = UIEdgeInsets(top: scrollTopInset, left: 0, bottom: 0, right: 0)
    
    if pullToRefresh {
      refreshControl = UIRefreshControl()
      refreshControl?.addTarget(self, action: #selector(didPullToRefresh(refreshControl:)), for: .valueChanged)
      scrollView.refreshControl = refreshControl
    }
    
    // Subscribe to data loader notifications
    subscribeToDataLoaderNotifications()

    // Table
    //    container.autohide = true
    //    container.autostart = false
    
    // Make sure Search Bar is on top
    if let searchBar = searchBar {
      view.bringSubview(toFront: searchBar)
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
    
    if allowSearch {
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let loadType = refreshOnAppear, dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized {
      loadRows(loadType: loadType)
    } else if dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized && dataLoader.isEmpty {
      loadRows(loadType: .replace)
    }
  }
  
  open func searchKeyboardWillShow(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        scrollBottomInset = scrollView.contentInset.bottom
        
        UIView.animate(
          withDuration: animationDuration,
          delay: 0,
          options: [.beginFromCurrentState, .allowUserInteraction],
          animations: {
            self.scrollView.contentInset.bottom = keyboardSize.height
          },
          completion: nil
        )
      }
    }
  }
  
  open func searchKeyboardWillHide(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      UIView.animate(
        withDuration: animationDuration,
        delay: 0,
        options: [.beginFromCurrentState, .allowUserInteraction],
        animations: {
          let bottomInset = self.scrollBottomInset ?? 0
          self.scrollView.contentInset.bottom = bottomInset
        },
        completion: nil
      )
    }
  }
  
  open func didPullToRefresh(refreshControl: UIRefreshControl) {
    loadRows(loadType: .replace)
  }
  
  // MARK: - Querying
  open func loadRows(loadType: DataLoadType) {
    if dataLoader.rowsLoading && loadType != .clearAndReplace {
      return
    }
    
    dataLoader.loadRows(loadType: loadType)?.catch { [weak self] error in
      // TODO: Better handle error
      if let rows = self?.dataLoader.rowsToDisplay, rows.count == 0 {
        self?.loaderView.showEmptyView()
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
  }
  
  open func handleResultsReceivedNotification(_ notification: Notification) {
    let loadType = dataLoader.loadTypeFromNotification(notification)

    if loadType != .more {
      refreshControl?.endRefreshing()
    }
    
  }
  
  open func handleDidFinishLoadingRowsNotification(_ notification: Notification) {
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
  open func didUpdateRowDataUI() {
    // searchBar?.isHidden = dataLoader.isEmpty
    checkEmpty()
  }
  
  open var rowCRUDCompletion: (Bool) -> Void {
    return { complete in
      if self.dataLoader.isEmpty {
        self.refreshScrollView()
      }
      
      self.didUpdateRowDataUI()
    }
  }
  
  // MARK: - DataLoaderDelegate
  open func didInsertRowAtIndex(_ index: Int) {
    if let collectionView = scrollView as? UICollectionView {
      collectionView.performBatchUpdates({
        collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
      }, completion: rowCRUDCompletion)
    } else if let tableView = scrollView as? UITableView {
      tableView.performBatchUpdates({
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
      }, completion: rowCRUDCompletion)
    }
  }
  
  open func didUpdateRowAtIndex(_ index: Int) {
    if let collectionView = scrollView as? UICollectionView {
      collectionView.performBatchUpdates({
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
      }, completion: rowCRUDCompletion)
    } else if let tableView = scrollView as? UITableView {
      tableView.performBatchUpdates({
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
      }, completion: rowCRUDCompletion)
    }
  }

  open func didRemoveRowAtIndex(_ index: Int) {
    if let collectionView = scrollView as? UICollectionView {
      collectionView.performBatchUpdates({
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
      }, completion: rowCRUDCompletion)
    } else if let tableView = scrollView as? UITableView {
      tableView.performBatchUpdates({
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
      }, completion: rowCRUDCompletion)
    }    
  }
  
  open func didClearRows() {
    refreshScrollView()
    loaderView.showSpinner()
  }
  
  open func didStartLoadingRows(loadType: DataLoadType) {    
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
  
  // MARK: - Displaying results
  open func initialDisplay() {
    UIView.animate(
      withDuration: Const.fadeDuration,
      delay: 0,
      options: .allowUserInteraction,
      animations: { self.container.alpha = 1.0 },
      completion: nil
    )
  }
  
  open func checkEmpty() {
    if dataLoader.isEmpty {
      scrollView.isHidden = true
      loaderView.showEmptyView()
    } else {
      scrollView.isHidden = false
      loaderView.isHidden = true
    }
  }
  
  open func refreshScrollView() {
    listAdapter.reloadData()
  }
  
  // MARK: - CollectionSearchBarDelegate
  open func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    if searchBar.throttle == nil {
      dataLoader.searchByString(searchBar.text)
    }
  }
  
  open func searchBarDidTapClearButton(_ searchBar: CollectionSearchBar) {
    
  }
  
  open func searchBarTextDidBeginEditing(_ searchBar: CollectionSearchBar) {
    
  }
  
  open func searchBarTextDidChangeAfterThrottle(_ searchBar: CollectionSearchBar) {
    dataLoader.searchByString(searchBar.text)
  }
  
  // MARK: - Filters
  open func clearFilters() {
    for filter in filters {
      filter.clearFilter()
    }
  }
}
