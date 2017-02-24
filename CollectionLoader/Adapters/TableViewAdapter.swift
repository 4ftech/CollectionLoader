//
//  TableViewAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public class TableViewAdapter<A: CellAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UITableViewDelegate, UITableViewDataSource {
  public typealias CellAdapterType = A
  public typealias EngineType = E
  
  public var collectionViewType: CollectionViewType = .table
  
  public var cellAdapter: A!
  public weak var dataLoader: DataLoader<E>!
  
  public required override init() {
    super.init()
    
    self.cellAdapter = A()
  }
  
  public init(cellAdapter: A) {
    super.init()
    
    self.cellAdapter = cellAdapter
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
    cellAdapter.apply(row: row as! A.T, toCell: cell as! CellAdapterType.C)
    
    return cell
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.didTapCell(forRow: row as! A.T)
  }
}

