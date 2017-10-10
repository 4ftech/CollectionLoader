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
import Changeset

import DataSource

open class ListLoaderController<AdapterType: BaseListAdapter>: UIViewController, CollectionSearchBarDelegate, DataLoaderDelegate {
  deinit {
    NSLog("deinit: \(type(of: self))")
  }

  let singleLineTableCellIdentifier = "singleLineIconCell"
  let twoLineTableCellIdentifier = "twoLineIconCell"
  let threeLineTableCellIdentifier = "threeLineIconCell"

  typealias m = LoaderView
  
  public var loaderView: LoaderView!
  public var listAdapter: AdapterType!
  
  public var scrollsToInsertedRow: Bool = false
  public var pullToRefresh: Bool = false
  var refreshControl: UIRefreshControl?

  public var container: UIView!
  public var emptyViewContent: EmptyViewContent?
  public var errorViewContent: (() -> EmptyViewContent)?
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
    var topInset: CGFloat = topBarInset
    
    if let searchBar = searchBar, allowSearch {
      topInset = topInset + searchBar.frame.size.height
    }
    
    return topInset
  }
  
  open var topBarInset: CGFloat {
    var topInset: CGFloat = 0
    
    if let navController = navigationController, !navController.isNavigationBarHidden && ((extendedLayoutIncludesOpaqueBars && edgesForExtendedLayout.contains(.top)) || navController.navigationBar.isTranslucent) {
      topInset = topInset + Const.topBarHeight
    }
    
    return topInset
  }
  
  open var scrollBottomInset: CGFloat?
  
  // DATA
  public var dataLoader: DataLoader<AdapterType.EngineType> {
    return listAdapter.dataLoader
  }
  
  public var dataLoaderEngine: AdapterType.EngineType {
    return dataLoader.dataLoaderEngine
  }
  
  public var collectionInitialized = false
  public var refreshOnAppear: DataLoadType? = nil
  public var rowsLoading: Bool { return dataLoader.rowsLoading }
  public var rowsLoaded: Bool { return dataLoader.rowsLoaded }
  public var rows: [AdapterType.EngineType.T] { return dataLoader.rowsToDisplay }
  
  public var disposeBag: DisposeBag = DisposeBag()
  
  // MARK: - Initialize
  public init(listAdapter: AdapterType) {
    super.init(nibName: nil, bundle: nil)
    
    self.listAdapter = listAdapter
    self.listAdapter.viewController = self
    
    self.emptyViewContent = EmptyViewContent(message: "No results")
    self.errorViewContent = { [weak self] in
      return EmptyViewContent(
        message: "Error",
        subtitle: "We had trouble with your last request. Please try again or contact us if this issue persists.",
        buttonText: "Try Again",
        buttonAction: { [weak self] in
          self?.loadRows(loadType: .clearAndReplace)
        }
      )
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Controller
  override open func viewDidLoad() {
    super.viewDidLoad()

    self.automaticallyAdjustsScrollViewInsets = false
    
    // Don't set delegate until view is loaded
    self.dataLoader.delegate = self
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
    scrollView.keyboardDismissMode = .interactive
    container.fill(withView: scrollView)
    
    // Loader
    if loaderView == nil {
      loaderView = LoaderView.newInstance(content: emptyViewContent)
    }
    
    view.fill(
      withView: loaderView,
      edgeInsets: UIEdgeInsets(top: scrollTopInset, left: 0, bottom: 0, right: 0)
    )
    
    // ScrollView
    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.keyboardDismissMode = .interactive
    
    if scrollBottomInset == nil {
      if let parentController = parent, parentController is UITabBarController || (
        parentController is UINavigationController &&
        parentController.parent is UITabBarController
      ) {
        scrollBottomInset = Const.tabBarHeight
      }
    }
    
    scrollView.contentInset = UIEdgeInsets(top: scrollTopInset, left: 0, bottom: (scrollBottomInset ?? 0), right: 0)
    
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
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let loadType = refreshOnAppear, dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized {
      loadRows(loadType: loadType)
    } else if dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized && dataLoader.isEmpty {
      loadRows(loadType: .replace)
    }    
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
  }
  
  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    self.searchBar?.textField.resignFirstResponder()
    self.searchKeyboardWillHide(animationDuration: Const.keyboardAnimationDuration)
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    self.refreshControl?.endRefreshing()
    
    NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
  }
  
  open func searchKeyboardWillShow(_ notification: Notification) {
    if UIApplication.shared.applicationState != .active {
      return
    }
    
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        UIView.animate(
          withDuration: animationDuration,
          delay: 0,
          options: [.beginFromCurrentState, .allowUserInteraction],
          animations: {
            self.scrollView.contentInset.bottom = keyboardSize.height + (self.scrollBottomInset ?? 0)
          },
          completion: nil
        )
      }
    }
  }
  
  open func searchKeyboardWillHide(_ notification: Notification) {
    if UIApplication.shared.applicationState != .active {
      return
    }

    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      self.searchKeyboardWillHide(animationDuration: animationDuration)
    }
  }
  
  open func searchKeyboardWillHide(animationDuration: Double) {
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
  
  open func didPullToRefresh(refreshControl: UIRefreshControl) {
    loadRows(loadType: .replace)
  }
  
  // MARK: - Querying
  open func loadRows(loadType: DataLoadType) {
    if dataLoader.rowsLoading && loadType != .clearAndReplace {
      return
    }
    
    dataLoader.loadRows(loadType: loadType)?.catch { [weak self] error in
      if let rows = self?.dataLoader.rowsToDisplay, rows.count == 0 {
        self?.loaderView.showContent(self?.errorViewContent?())
      }
      
      self?.refreshControl?.endRefreshing()
      self?.scrollView.finishInfiniteScroll()
    }
  }
  
  open func subscribeToDataLoaderNotifications() {
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


  }
  
  open func handleDidFinishLoadingRowsNotification(_ notification: Notification) {
    let loadType = dataLoader.loadTypeFromNotification(notification)

    loaderView.hideSpinner()
    
    let completion: (Bool) -> Void = { complete in
      if loadType == .more {
        self.scrollView.finishInfiniteScroll()
        
        
        if let indicatorView = self.scrollView.infiniteScrollIndicatorView {
          // So that the new rows will fade in front of the indicator
          self.scrollView.sendSubview(toBack: indicatorView)
        }
      } else {
        self.refreshControl?.endRefreshing()
      }
      
      self.didUpdateRowDataUI()
    }
    
    if !collectionInitialized || loadType == .clearAndReplace || loadType == .initial {
      refreshScrollView()
      completion(true)
    } else if let edits = dataLoader.editsFromNotification(notification), edits.count > 0 {
      if loadType == .replace && scrollView.contentOffset.y > -scrollView.contentInset.top {
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: false)
      }
      
      updateScrollView(withEdits: edits, completion: completion)
    } else {
      completion(true)
    }

    if dataLoader.mightHaveMore {
      scrollView.addInfiniteScroll() { [weak self] scrollView in
        self?.loadRows(loadType: .more)
      }
      
      scrollView.infiniteScrollIndicatorMargin = 32
      scrollView.infiniteScrollTriggerOffset = UIScreen.main.bounds.height * 1.5
    } else {
      scrollView.removeInfiniteScroll()
    }
    
    
  }
  
  // MARK: - Manipulating data
  open func didUpdateRowDataUI() {
    // searchBar?.isHidden = dataLoader.isEmpty
    checkEmpty()
    
    if !collectionInitialized && !dataLoader.isEmpty {
      initialDisplay()
      collectionInitialized = true
    }
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
  open func dataLoader<E>(_ dataLoader: DataLoader<E>, didInsertRowAtIndex index: Int) {
    if dataLoader == self.dataLoader {
      if let collectionView = scrollView as? UICollectionView {
        let indexPath: IndexPath = IndexPath(item: index, section: 0)
        
        collectionView.performBatchUpdates({
          collectionView.insertItems(at: [indexPath])
        }, completion: { complete in
          if self.scrollsToInsertedRow {
            collectionView.scrollToItem(at: indexPath, at: self.dataLoader.newRowsPosition == .beginning ? .top : .bottom, animated: true)
          }
          
          self.rowCRUDCompletion(complete)
        })
      } else if let tableView = scrollView as? UITableView {
        let indexPath: IndexPath = IndexPath(row: index, section: 0)
        
        tableView.performBatchTableUpdates({
          tableView.insertRows(at: [indexPath], with: .fade)
          
        }, completion: { complete in
          if self.scrollsToInsertedRow {
            var isRowVisible: Bool = false
            if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
              for visibleIndexPath in visibleIndexPaths {
                if visibleIndexPath == indexPath {
                  isRowVisible = true
                  break
                }
              }
            }
            
            if !isRowVisible {
              tableView.scrollToRow(at: indexPath, at: self.dataLoader.newRowsPosition == .beginning ? .top : .bottom, animated: true)
            }
          }
          
          self.rowCRUDCompletion(complete)
        })
      }
    }
  }
  
  open func dataLoader<E>(_ dataLoader: DataLoader<E>, didUpdateRowAtIndex index: Int) {
    if dataLoader == self.dataLoader {
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }, completion: rowCRUDCompletion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchTableUpdates({
          tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }, completion: rowCRUDCompletion)
      }
    }
  }

  open func dataLoader<E>(_ dataLoader: DataLoader<E>, didRemoveRowAtIndex index: Int) {
    if dataLoader == self.dataLoader {
      if let collectionView = scrollView as? UICollectionView {
        collectionView.performBatchUpdates({
          collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }, completion: rowCRUDCompletion)
      } else if let tableView = scrollView as? UITableView {
        tableView.performBatchTableUpdates({
          tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }, completion: rowCRUDCompletion)
      }
    }
  }
  
  open func dataLoader<E>(_ dataLoader: DataLoader<E>, didStartLoadingRowsWithLoadType loadType: DataLoadType) {
    if dataLoader == self.dataLoader {
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
  }
  
  open func dataLoaderDidClearRows<E>(_ dataLoader: DataLoader<E>) {
    if dataLoader == self.dataLoader {
      refreshScrollView()
      loaderView.showSpinner()
    }
  }
  
  open func dataLoader<E>(_ dataLoader: DataLoader<E>, didCatchLoadingError error: Error) {
    
  }
  
  // MARK: - Displaying results
  open func initialDisplay() {
    UIView.animate(
      withDuration: Const.fadeDuration,
      delay: 0,
      options: [.allowUserInteraction, .beginFromCurrentState],
      animations: { self.container.alpha = 1.0 },
      completion: nil
    )
  }
  
  open func checkEmpty() {
    if dataLoader.isEmpty {
      scrollView.isHidden = true
      loaderView.showContent(self.emptyViewContent)
    } else {
      scrollView.isHidden = false
      loaderView.isHidden = true
    }
  }
  
  open func refreshScrollView() {
    listAdapter.reloadData()
  }
  
  open func updateScrollView(withEdits edits: [Edit<AdapterType.EngineType.T>], completion: ((Bool) -> Void)? = nil) {
    listAdapter.update(withEdits: edits, completion: completion)
  }
  
  // MARK: - CollectionSearchBarDelegate
  open func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    if searchBar.throttle == nil {
      dataLoader.searchByString(searchBar.text)
    }
  }
  
  open func searchBarDidTapClearButton(_ searchBar: CollectionSearchBar) {
    dataLoader.searchByString(nil)
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
