//
//  TableViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

public class TableViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UITableViewDelegate, UITableViewDataSource {
  public typealias CellAdapterType = A
  public typealias EngineType = E
  
  public var collectionViewType: CollectionViewType = .table
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!
  public weak var viewController: UIViewController!
  public var selectedIds: [String] = []
  
  public required init(cellAdapter: A, dataLoaderEngine: E) {
    super.init()
    
    self.cellAdapter = cellAdapter
    self.dataLoader = DataLoader<E>(dataLoaderEngine: dataLoaderEngine)
  }
  
  public func registerCells<T: UIScrollView>(scrollView: T) {
    if let tableView = scrollView as? UITableView {
      for cellType in cellAdapter.cellTypes {
        tableView.register(cellType.nib, forCellReuseIdentifier: cellType.identifier)
      }
    }
  }
  
  public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T.T)
    
    let mappableCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! A.T
    mappableCell.map(object: row as! A.T.T)
    
    let cell = mappableCell as! UITableViewCell
    if let objectId = row.objectId, selectedIds.contains(objectId) {
      cell.setSelected(true, animated: true)
    } else {
      cell.setSelected(false, animated: true)
    }
    
    return cell
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onTapCell?(row as! A.T.T, viewController)
  }
}

