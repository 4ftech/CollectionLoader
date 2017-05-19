//
//  TableViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper

open class TableViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UITableViewDelegate, UITableViewDataSource {
  public typealias EngineType = E
  
  public var tableView: UITableView!
  public var scrollView: UIScrollView {
    return tableView
  }
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!

  public weak var viewController: UIViewController!
  
  public init(cellAdapter: A, dataLoader: DataLoader<E>) {
    super.init()
    
    self.cellAdapter = cellAdapter
    self.dataLoader = dataLoader
    
    self.tableView = UITableView()
    self.tableView.delegate = self
    self.tableView.dataSource = self    
  }
  
  public convenience init(cellAdapter: A, dataLoaderEngine: E) {
    self.init(cellAdapter: cellAdapter, dataLoader: DataLoader<E>(dataLoaderEngine: dataLoaderEngine))
  }
  
  public convenience init(cellAdapter: A) {
    self.init(cellAdapter: cellAdapter, dataLoaderEngine: E())
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
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T.T)
    
    let mappableCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! A.T
    mappableCell.map(object: row as! A.T.T)
    cellAdapter.onDequeueCell?(mappableCell)
    
    let cell = mappableCell as! UITableViewCell
    
    return cell
  }
  
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row as! A.T.T, viewController)
  }
  
  open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row as! A.T.T, viewController)
  }
  
  open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    
  }
  
  open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.canDelete?(row as! A.T.T) ?? false
  }
  
  open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let row = dataLoader.rowsToDisplay[indexPath.row]
      row.delete().then { success in
        NotificationCenter.default.postCRUDNotification(.delete, crudObject: row)
      }.catch { error in
            
      }
    }
  }
  
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row as! A.T.T).height ?? tableView.rowHeight
  }
  
  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return nil
  }
  
  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return nil
  }
  
  open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }
}

