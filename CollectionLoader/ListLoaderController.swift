//
//  ListLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import RxSwift
import UIScrollView_InfiniteScroll
import UIKit

open class ListLoaderController<AdapterType: BaseCollectionAdapter>: UIViewController, CollectionSearchBarDelegate, DataLoaderDelegate {
  let singleLineTableCellIdentifier = "singleLineIconCell"
  let twoLineTableCellIdentifier = "twoLineIconCell"
  let threeLineTableCellIdentifier = "threeLineIconCell"

  typealias m = LoaderView
  
  public var loaderView: LoaderView!
  var collectionAdapter: AdapterType!
  var refreshControl: UIRefreshControl?

  public var pullToRefresh: Bool = false

  public var container: UIView!
  public var emptyViewContent: EmptyViewContent?
  public var scrollView: UIScrollView {
    return collectionAdapter.scrollView
  }  
  
  // Search
  public var allowSearch: Bool = false
  var searchBar: CollectionSearchBar?
  
  // Insets
  var scrollTopInset: CGFloat {
    var topInset: CGFloat = 0
    
    if allowSearch {
      topInset = topInset + Const.searchBarHeight
    }
    
    return topInset
  }
  
  var topBarInset: CGFloat {
    var topInset: CGFloat = 0
    
    if let navController = navigationController, !navController.isNavigationBarHidden && extendedLayoutIncludesOpaqueBars && edgesForExtendedLayout.contains(.top) {
      topInset = topInset + Const.topBarHeight
    }
    
    return topInset
  }
  
  var scrollBottomInset: CGFloat?
  
  // DATA
  var collectionInitialized = false
  var dataLoader: DataLoader<AdapterType.EngineType>!
  var disposeBag: DisposeBag = DisposeBag()

  public var refreshOnAppear: DataLoadType? = nil  
  public var rowsLoading: Bool { return dataLoader.rowsLoading }
  public var rowsLoaded: Bool { return dataLoader.rowsLoaded }
  public var rows: [AdapterType.EngineType.T] { return dataLoader.rowsToDisplay }
  
  // MARK: - Initialize
  public init(collectionAdapter: AdapterType) {
    super.init(nibName: nil, bundle: nil)
    
    self.collectionAdapter = collectionAdapter
    self.collectionAdapter.viewController = self
    
    self.dataLoader = collectionAdapter.dataLoader
    self.dataLoader.delegate = self
    
    self.emptyViewContent = EmptyViewContent(message: "No results")

  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Controller
  override open func viewDidLoad() {
    super.viewDidLoad()

    NSLog("viewDidLoad for ListLoaderController")
    
    //    edgesForExtendedLayout = []
    //    extendedLayoutIncludesOpaqueBars = false
    //    automaticallyAdjustsScrollViewInsets = true
    
    view.backgroundColor = UIColor.white

    // Add Container and ScrollView
    container = UIView(frame: view.frame)
    container.alpha = 0
    view.fill(withView: container)
    
    collectionAdapter.registerCells()
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
    
    // Search
    if allowSearch {
      searchBar = CollectionSearchBar.newInstance()
      searchBar?.delegate = self
      searchBar?.isHidden = false
      view.addView(
        searchBar!,
        onEdge: .top,
        edgeInsets: UIEdgeInsets(top: topBarInset, left: 0, bottom: 0, right: 0)
      )
    }
    
    // Filters
    
    // Table
    //    container.autohide = true
    //    container.autostart = false
    
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
    
    if allowSearch {
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if allowSearch {
      NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
  }
  
  func searchKeyboardWillShow(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
        scrollBottomInset = scrollView.contentInset.bottom
        
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
        let bottomInset = self.scrollBottomInset ?? 0
        self.scrollView.contentInset.bottom = bottomInset
      }, completion: nil)
    }
  }
  
  func didPullToRefresh(refreshControl: UIRefreshControl) {
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
  
  // MARK: DataLoaderDelegate
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
  
  // MARK: - Displaying results
  open func initialDisplay() {
    UIView.animate(withDuration: 1.0, animations: {
      self.container.alpha = 1.0
    })
  }
  
  open func checkEmpty() {
    if dataLoader.isEmpty {
      loaderView.showEmptyView()
    } else {
      loaderView.isHidden = true
    }
  }
  
  open func refreshScrollView() {
    collectionAdapter.reloadData()
  }
  
  // MARK: - CollectionSearchBarDelegate
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    dataLoader.searchByString(searchBar.text)
  }
}
