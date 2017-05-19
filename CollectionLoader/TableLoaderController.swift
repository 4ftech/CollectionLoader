//
//  TableLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 5/18/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableLoaderController<A: CellMapperAdapter, E: DataLoaderEngine>: ListLoaderController<TableViewMapperAdapter<A, E>> {
  public var tableView: UITableView {
    return scrollView as! UITableView
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(cellAdapter: A, dataLoader: DataLoader<E>) {
    super.init(collectionAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoader: dataLoader))
  }

  public init(cellAdapter: A, dataLoaderEngine: E) {
    super.init(collectionAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoaderEngine: dataLoaderEngine))
  }

  public init(cellAdapter: A) {
    super.init(collectionAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter))
  }
}
