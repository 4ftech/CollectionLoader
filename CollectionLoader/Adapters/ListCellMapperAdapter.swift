//
//  ListCellMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation
import UIKit

import ViewMapper
import DataSource

open class ListCellMapperAdapter<C: CellMapperAdapter, E>: ListAdapter<C.T.T, E> where E: DataLoaderEngine<C.T.T> {
  public typealias T = C.T.T
  public var cellAdapter: C!
  public weak var viewController: UIViewController?
  
  public init(cellAdapter: C,
              dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: E()),
              viewController: UIViewController? = nil,
              initialize: ((C) -> Void)? = nil) {
    
    super.init(dataLoader: dataLoader)
    
    self.initialize(cellAdapter: cellAdapter,
                    viewController: viewController,
                    initialize: initialize)
  }
  
  public init(cellAdapter: C,
              dataLoaderEngine: E,
              viewController: UIViewController? = nil,
              initialize: ((C) -> Void)? = nil) {
    
    super.init(dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine))
    
    self.initialize(cellAdapter: cellAdapter,
                    viewController: viewController,
                    initialize: initialize)
  }
  
  open func initialize(cellAdapter: C,
                       viewController: UIViewController? = nil,
                       initialize: ((C) -> Void)? = nil) {
    
    self.cellAdapter = cellAdapter
    self.viewController = viewController
    
    initialize?(self.cellAdapter)
  }
  
  open override func registerCells(scrollView: UIScrollView) {
    super.registerCells(scrollView: scrollView)
    
    if let tableView = scrollView as? UITableView {
      for cellType in cellAdapter.cellTypes {
        cellType.register(tableView: tableView)
      }
    } else if let collectionView = scrollView as? UICollectionView {
      for cellType in cellAdapter.cellTypes {
        cellType.register(collectionView: collectionView)
      }

      collectionView.register(UICollectionReusableView.self,
                              forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                              withReuseIdentifier: String(describing: UICollectionReusableView.self))
    }
  }
  
  // MARK: - UIScrollView
  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    cellAdapter.onScrollViewDidScroll?(scrollView)
  }
  
  open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    cellAdapter.onScrollViewDidEndDecelerating?(scrollView)
  }
  
  open override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                              willDecelerate decelerate: Bool) {
    
    cellAdapter.onScrollViewDidEndDragging?(scrollView, decelerate)
  }
  
  // MARK: - UITableView
  open override func tableView(_ tableView: UITableView,
                               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row)
    
    let mappableCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! C.T
    cellAdapter.onDequeueCell?(mappableCell, row, indexPath)
    mappableCell.map(object: row)
    
    let cell = mappableCell as! UITableViewCell
    
    return cell
  }
  
  open override func tableView(_ tableView: UITableView,
                               didSelectRowAt indexPath: IndexPath) {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row, self.viewController)
  }
  
  open override func tableView(_ tableView: UITableView,
                               accessoryButtonTappedForRowWith indexPath: IndexPath) {
    
  }
  
  open override func tableView(_ tableView: UITableView,
                               didDeselectRowAt indexPath: IndexPath) {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row, self.viewController)
  }
  
  open override func tableView(_ tableView: UITableView,
                               canEditRowAt indexPath: IndexPath) -> Bool {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.canDelete?(row) ?? false
  }
  
  
  open override func tableView(_ tableView: UITableView,
                               heightForRowAt indexPath: IndexPath) -> CGFloat {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row).height ?? tableView.rowHeight
  }
  
  open override func tableView(_ tableView: UITableView,
                               estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    
    if indexPath.row < dataLoader.rowsToDisplay.count {
      let row = dataLoader.rowsToDisplay[indexPath.row]
      return cellAdapter.size?(row).height ?? tableView.rowHeight
    } else {
      return tableView.rowHeight
    }
  }
  
  open override func tableView(_ tableView: UITableView,
                               viewForHeaderInSection section: Int) -> UIView? {
    
    return cellAdapter.sectionHeader?(section)
  }
  
  open override func tableView(_ tableView: UITableView,
                               heightForHeaderInSection section: Int) -> CGFloat {
    
    return cellAdapter.sectionHeaderHeight?(section) ?? 0
  }
  
  // MARK: - UICollectionView
  open override func collectionView(_ collectionView: UICollectionView,
                                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row)
    
    let mappableCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! C.T
    cellAdapter.onDequeueCell?(mappableCell, row, indexPath)
    mappableCell.map(object: row)
    
    let cell = mappableCell as! UICollectionViewCell
    return cell
  }
  
  open override func collectionView(_ collectionView: UICollectionView,
                                    didSelectItemAt indexPath: IndexPath) {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row, self.viewController)
  }
  
  open override func collectionView(_ collectionView: UICollectionView,
                                    didDeselectItemAt indexPath: IndexPath) {
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row, self.viewController)
  }
  
  open override func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row) ?? flowLayout.itemSize
  }
  
  open override func collectionView(_ collectionView: UICollectionView,
                                    viewForSupplementaryElementOfKind kind: String,
                                    at indexPath: IndexPath) -> UICollectionReusableView {
    
    let header: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(describing: UICollectionReusableView.self), for: indexPath)
    
    if let view = cellAdapter.sectionHeader?(indexPath.section) {
      header.fill(withView: view)
    }
    
    return header
  }
  
  open override func collectionView(_ collectionView: UICollectionView,
                                    layout collectionViewLayout: UICollectionViewLayout,
                                    referenceSizeForHeaderInSection section: Int) -> CGSize {
    
    if let height = cellAdapter.sectionHeaderHeight?(section) {
      return CGSize(width: UIScreen.main.bounds.width, height: height)
    } else {
      return .zero
    }
  }
}
