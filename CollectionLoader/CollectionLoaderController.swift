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


open class CollectionLoaderController<AdapterType: BaseCollectionAdapter>: UIViewController, CollectionSearchBarDelegate, DataLoaderDelegate {
  let singleLineTableCellIdentifier = "singleLineIconCell"
  let twoLineTableCellIdentifier = "twoLineIconCell"
  let threeLineTableCellIdentifier = "threeLineIconCell"

  public var emptyViewContent: EmptyViewContent?
  
  typealias m = LoaderView
  var container: SpringView!
  var scrollView: UIScrollView!

  var loaderView: LoaderView!
  var refreshControl: UIRefreshControl?
  public var pullToRefresh: Bool = false
  
  var collectionAdapter: AdapterType!
  
  // Search
  public var allowSearch: Bool = true
  var searchBar: CollectionSearchBar?
  
  // Insets
  var scrollTopInset: CGFloat {
    var topInset: CGFloat = 0
    
    if allowSearch {
      topInset = topInset + Utils.searchBarHeight
    }
    
    return topInset
  }
  
  var topBarInset: CGFloat {
    var topInset: CGFloat = 0
    
    if let navController = navigationController, !navController.isNavigationBarHidden {
      topInset = topInset + Utils.topBarHeight
    }
    
    return topInset
  }
  
  // DATA
  var collectionInitialized = false
  var dataLoader: DataLoader<AdapterType.EngineType>!
  var disposeBag: DisposeBag = DisposeBag()

  public var refreshOnAppear: DataLoadType? = nil
  
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

    NSLog("viewDidLoad for CollectionLoaderController")
    
    //    edgesForExtendedLayout = []
    //    extendedLayoutIncludesOpaqueBars = false
    automaticallyAdjustsScrollViewInsets = true
    
    view.backgroundColor = UIColor.white

    // Add Container and ScrollView
    container = SpringView()
    container.alpha = 0
    Utils.fillContainer(view, withView: container)
    
    scrollView = collectionAdapter.scrollView
    collectionAdapter.registerCells()

    Utils.fillContainer(container, withView: scrollView)
    
    // Loader
    loaderView = LoaderView.newInstance(content: emptyViewContent)
    Utils.fillContainer(view, withView: loaderView, edgeInsets: UIEdgeInsets(top: topBarInset + scrollTopInset, left: 0, bottom: 0, right: 0))
    
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
      Utils.addView(searchBar!, toContainer: container, onEdge: .top, edgeInsets: UIEdgeInsets(top: topBarInset, left: 0, bottom: 0, right: 0))
      
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardDidShow(_:)), name: Notification.Name.UIKeyboardDidShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(searchKeyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
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
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let loadType = refreshOnAppear, dataLoader.rowsLoaded && !dataLoader.rowsLoading && collectionInitialized {
      loadRows(loadType: loadType)
    }
  }
  
  // MARK: - Querying
  func loadRows(loadType: DataLoadType) {
    if dataLoader.rowsLoading && loadType != .clearAndReplace {
      return
    }
    
    dataLoader.loadRows(loadType: loadType)?.catch { [weak self] error in
      self?.loaderView.showEmptyView()
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
  
  func handleResultsReceivedNotification(_ notification: Notification) {
    let loadType = dataLoader.loadTypeFromNotification(notification)

    if loadType != .more {
      refreshControl?.endRefreshing()
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
  func didUpdateRowDataUI() {
    // searchBar?.isHidden = dataLoader.isEmpty
    checkEmpty()
  }
  
  var rowCRUDCompletion: (Bool) -> Void {
    return { complete in
      if self.dataLoader.isEmpty {
        self.refreshScrollView()
      }
      
      self.didUpdateRowDataUI()
    }
  }
  
  // MARK: DataLoaderDelegate
  func didInsertRowAtIndex(_ index: Int) {
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
  
  func didUpdateRowAtIndex(_ index: Int) {
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

  func didRemoveRowAtIndex(_ index: Int) {
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
  
  func didClearRows() {
    refreshScrollView()
    loaderView.showSpinner()
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
    collectionAdapter.reloadData()
  }
  
  // MARK: - CollectionSearchBarDelegate
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar) {
    dataLoader.searchByString(searchBar.text)
  }
}
