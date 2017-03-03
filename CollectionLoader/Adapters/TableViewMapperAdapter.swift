//
//  TableViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UITableViewDelegate, UITableViewDataSource where A.T.T == E.T {
  public typealias EngineType = E
  
  public var tableView = UITableView()
  public var scrollView: UIScrollView {
    return tableView
  }
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!

  public weak var viewController: UIViewController!
  
  public required init(cellAdapter: A, dataLoaderEngine: E) {
    super.init()
    
    self.cellAdapter = cellAdapter
    self.dataLoader = DataLoader<E>(dataLoaderEngine: dataLoaderEngine)
    
    self.tableView.delegate = self
    self.tableView.dataSource = self
  }
  
  public func reloadData() {
    tableView.reloadData()
  }
  
  open func registerCells() {
    for cellType in cellAdapter.cellTypes {
      tableView.register(cellType.nib, forCellReuseIdentifier: cellType.identifier)
    }
  }
  
  open func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row)
    
    let mappableCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! A.T
    
    mappableCell.map(object: row)
    
    let cell = mappableCell as! UITableViewCell
    return cell
  }
  
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onTapCell?(row, viewController)
  }
  
  open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    
  }
  
  open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let row = dataLoader.rowsToDisplay[indexPath.row]
      row.delete().then { success in
        NotificationCenter.default.postCRUDNotification(.Delete, crudObject: row)
      }.catch { error in
          
      }
    }
  }
  
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row).height ?? tableView.rowHeight
  }
}

