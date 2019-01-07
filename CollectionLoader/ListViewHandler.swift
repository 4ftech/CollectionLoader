//
//  ListViewHandler.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/30/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation
import UIKit

open class ListViewHandler<L>: NSObject where L:UIScrollView {
  var scrollView: L!
  
  open func initializeScrollView(delegate: ListLoaderDelegate) -> L {
    if L.self == UITableView.self {
      let tableView = UITableView()
      tableView.dataSource = delegate
      tableView.delegate = delegate
      
      self.scrollView = (tableView as! L)
    } else if L.self == UICollectionView.self {
      let flowLayout = UICollectionViewFlowLayout()
      flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: flowLayout.itemSize.height)
      flowLayout.minimumInteritemSpacing = 0
      flowLayout.minimumLineSpacing = 0
      
      let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
      collectionView.dataSource = delegate
      collectionView.delegate = delegate
      collectionView.backgroundColor = UIColor.white
      
      self.scrollView = (collectionView as! L)
    } else {
      self.scrollView = (UIScrollView() as! L)
    }
    
    // Common behavior
    if #available(iOS 11.0, *) {
      self.scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
    }
    
    // ScrollView
    self.scrollView.alwaysBounceVertical = true
    self.scrollView.showsVerticalScrollIndicator = false
    self.scrollView.showsHorizontalScrollIndicator = false
    self.scrollView.keyboardDismissMode = .interactive
    
    return self.scrollView
  }
  
  func viewDidLoad() {
    if let tableView = self.scrollView as? UITableView {
      tableView.tableFooterView = UIView(frame: .zero)
    }
  }
}
