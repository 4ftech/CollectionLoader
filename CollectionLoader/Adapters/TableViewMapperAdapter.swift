//
//  TableViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper

open class TableViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: TableListAdapter<E> {
  public typealias CellAdapterType = A
  public var cellAdapter: A!
  
  public required init(cellAdapter: A, dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init(dataLoader: dataLoader)
    
    self.cellAdapter = cellAdapter
  }
  
  public required init(dataLoader: DataLoader<E>) {
    fatalError("init(dataLoader:) has not been implemented")
  }
  
  open override func registerCells() {
    for cellType in cellAdapter.cellTypes {
      tableView.register(cellType.nib, forCellReuseIdentifier: cellType.identifier)
    }
  }
  
  open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T.T)
    
    let mappableCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! A.T
    mappableCell.map(object: row as! A.T.T)
    cellAdapter.onDequeueCell?(mappableCell, indexPath)
    
    let cell = mappableCell as! UITableViewCell
    
    return cell
  }
  
  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row as! A.T.T, viewController)
  }
  
  open override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row as! A.T.T, viewController)
  }
  
  open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.canDelete?(row as! A.T.T) ?? false
  }
  

  open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row as! A.T.T).height ?? tableView.rowHeight
  }
  
  open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return cellAdapter.sectionHeader?(section)
  }
  
  open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return cellAdapter.sectionHeaderHeight?(section) ?? 0
  }  

}

