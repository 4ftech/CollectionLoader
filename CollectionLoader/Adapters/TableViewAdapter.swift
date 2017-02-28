//
//  TableViewAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public class TableViewAdapter<A: CollectionRowCellAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UITableViewDelegate, UITableViewDataSource {
  public typealias CellAdapterType = A
  public typealias EngineType = E
  
  public var collectionViewType: CollectionViewType = .table
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!
  public weak var delegate: BaseCollectionDelegate?
  
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
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T)
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    cellAdapter.apply(row: row as! A.T, toCell: cell as! CellAdapterType.U)
    
    return cell
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    delegate?.didTapCell(forRow: row)
  }
}

