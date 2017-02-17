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

public class CollectionLoaderController<T: CollectionRow>: UIViewController, CollectionSearchBarDelegate {
  var container: SpringView!
  var scrollView: UIScrollView!

  var collectionViewType: CollectionViewType = .table
  
  var emptyViewContent: EmptyViewContent?
  var loaderView: LoaderView!
  var pullToRefresh: Bool = false
  var refreshControl: UIRefreshControl?
  
  // Search
  var allowSearch: Bool = false
  var searchBar: CollectionSearchBar?
  var showSearchResults: Bool {
    if let text = searchBar?.text, !text.isEmpty {
      return true
    } else {
      return false
    }
    
  }
  
  var searchFilter: ((T) -> Bool) {
    return { object in
      return false
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
  
  var navBarTitle: String? = nil
  
  // DATA
  var collectionInitialized = false
  var dataLoader: DataLoader<T>!
  var disposeBag: DisposeBag = DisposeBag()
  var startWithRows: [T] = []

  var rowsToExclude: [T] = []
  var rows: [T] {
    let rows = dataLoader.rows.filter { !rowsToExclude.contains($0) }
    
    if showSearchResults {
      return rows.filter(searchFilter)
    } else {
      return rows
    }
  }
  
  var refreshOnAppear: DataLoadType? = .newRows
  var isEmpty: Bool { return rows.count == 0 }
  
  // MARK: - Initialize
  required public init(collectionViewType: CollectionViewType? = nil, navBarTitle: String? = nil, emptyViewContent: EmptyViewContent? = nil) {
    super.init(nibName: nil, bundle: nil)
    
    if let viewType = collectionViewType {
      self.collectionViewType = viewType
    }
    
    self.navBarTitle = navBarTitle
    self.emptyViewContent = emptyViewContent
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func initializeDataLoader() {
    dataLoader = DataLoader<T>(rows: startWithRows)
  }
  
  func initializeLoaderView() {
    loaderView = LoaderView.newInstance(content: emptyViewContent)
    
    Utils.fillContainer(view, withView: loaderView)
  }
  
  // MARK: - Controller
  override public func viewDidLoad() {
    super.viewDidLoad()

    container = SpringView()
    Utils.fillContainer(view, withView: container)
    
    switch collectionViewType {
    case .collection:
      scrollView = UICollectionView()
    case .table:
      scrollView = UITableView()
    }

    Utils.fillContainer(container, withView: scrollView)
    
    // Loader
    initializeDataLoader()
    initializeLoaderView()
    
    // NavBar
    navigationItem.title = navBarTitle
    
    // Table
    container.autohide = true
    container.autostart = false

    // ScrollView
    setUpScrollView()
    
    // Register cells
    registerCells()
    
    // Subscribe to data loader notifications
    registerViewsWithDataLoader()
    subscribeToDataLoaderNotifications()
    
    // Search
    if allowSearch {
      searchBar = CollectionSearchBar.newInstance()
      searchBar?.delegate = self
      searchBar?.isHidden = isEmpty
      Utils.addView(searchBar!, toContainer: container, onEdge: .top)
      
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardDidShow(_:)), name: Notification.Name.UIKeyboardDidShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // OK GO
    if !dataLoader.rowsLoaded && !dataLoader.rowsLoading {
      loadRows(loadType: .initial)
    } else if dataLoader.rowsLoaded {
      self.didUpdateRowDataUI()
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
  
  func setUpScrollView() {
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false

    scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
  }
  
  func initPullToRefresh() {
    if refreshControl == nil {
      refreshControl = UIRefreshControl()
      refreshControl?.addTarget(self, action: #selector(didPullToRefresh(refreshControl:)), for: .valueChanged)
    }
    
    scrollView.refreshControl = refreshControl
  }
  
  func didPullToRefresh(refreshControl: UIRefreshControl) {
    loadRows(loadType: .newRows)
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let loadType = refreshOnAppear, dataLoader.rowsLoaded && !dataLoader.rowsLoading {
      loadRows(loadType: loadType)
    }
  }
    
  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if pullToRefresh && dataLoader.rowsLoaded && !dataLoader.rowsLoading {
      if !isEmpty {
        initPullToRefresh()
      } else {
        scrollView.refreshControl = nil
      }
    }
    
  }
  
  func registerCells() {
    
  }
  
  // MARK: - Data loader
  //  deinit {
  //    NSLog("deinit: \(self.dynamicType)")
  //  }
  
  func registerViewsWithDataLoader() {
    dataLoader.registerLoaderView(loaderView)
    dataLoader.registerScrollView(scrollView)
  }
  
  func subscribeToDataLoaderNotifications() {
    dataLoader.observerForAction(.ResultsReceived)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        if let realSelf = self {
          let loadType = realSelf.dataLoader.loadTypeFromNotification(notification)
          let results = realSelf.dataLoader.resultsFromNotification(notification)
          let resultCount = results?.count ?? 0
          
          if loadType != .more {
            realSelf.refreshControl?.endRefreshing()
            
            if realSelf.pullToRefresh && realSelf.dataLoader.rowsLoaded {
              if !realSelf.isEmpty || resultCount > 0 {
                realSelf.initPullToRefresh()
              } else {
                realSelf.scrollView.refreshControl = nil
              }
            }
          }
        }
      }).addDisposableTo(disposeBag)

    dataLoader.observerForAction(.FinishedLoading)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        self?.handleDidFinishLoadingRowsNotification(notification)
      }).addDisposableTo(disposeBag)
    
    dataLoader.observerForAction(.CRUD)
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        if let (type, object, index) = self?.dataLoader.rowUpdateInfoFromNotification(notification) {
          
          // NSLog("base collection loader (\(self) -- \(self?.dataLoader.notificationNamePrefix)) received notification: \(type) \(object) \(index)")
          
          switch type {
          case .Create:
            self?.didInsertRow(object, atIndex: index)
          case .Update:
            self?.didUpdateRow(object, atIndex: index)
          case .Delete:
            self?.didRemoveRow(object, atIndex: index)
          }
          
          self?.didUpdateRowDataUI()
        }
      }).addDisposableTo(disposeBag)
  }
  
  func handleDidFinishLoadingRowsNotification(_ notification: Notification) {
    let results = dataLoader.resultsFromNotification(notification)
    let loadType = dataLoader.loadTypeFromNotification(notification)
    dataLoaderDidFinishLoadingRows(results, loadType: loadType)
  }
  

  // MARK: - Querying
  func loadRows(loadType: DataLoadType) {
    dataLoader.loadRows(loadType: loadType)
  }
  
  func dataLoaderDidFinishLoadingRows(_ newResults: [T]?, loadType: DataLoadType) {
    if !collectionInitialized {
      initialDisplay()
      collectionInitialized = true
    }
    
    didUpdateRowDataUI()
    
    if dataLoader.mightHaveMore {
      scrollView.addInfiniteScroll() { [weak self] scrollView in
        self?.loadRows(loadType: .more)
      }
      scrollView.infiniteScrollIndicatorMargin = 24
    } else {
      scrollView.removeInfiniteScroll()
    }

  }
  
  // MARK: - Manipulating data
  func containsRow(_ object: T) -> Bool {
    return dataLoader.rows.contains(object)
  }
  
  func removeRow(_ object: T) {
    dataLoader.removeRowForObject(object)
  }
  
  func removeRowAtIndex(_ index: Int) -> T? {
    return dataLoader.removeRowAtIndex(index)
  }
  
  func appendRow(_ object: T) {
    dataLoader.appendRow(object)
  }
  
  func insertRow(_ object: T, atIndex index: Int) {
    dataLoader.insertRow(object, atIndex: index)
  }
  
  func didRemoveRow(_ object: T, atIndex index: Int) {
    
  }

  func didUpdateRow(_ object: T, atIndex index: Int) {
    
  }
  
  func didInsertRow(_ object: T, atIndex index: Int) {
    
  }

  func didUpdateRowDataUI() {
    searchBar?.isHidden = isEmpty
  }

  // MARK: - Displaying results
  func initialDisplay() {
    container.animation = "fadeIn"
    container.duration = 1.0
    container.animate()
  }
  
  func refresh() {
    checkEmpty()
  }

  func object(at indexPath: IndexPath) -> T {
    return rows[indexPath.row]
  }

  // MARK: - Spinner and empty view
  func showSpinner() {
    loaderView.showSpinner()
  }
  
  func hideSpinner() {
    loaderView.hideSpinner()
  }
  
  func checkEmpty() {
    if isEmpty {
      loaderView.showEmptyView()
    } else {
      loaderView.isHidden = true
    }
  }

  // MARK: - CollectionSearchBarDelegate
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    
  }
}
