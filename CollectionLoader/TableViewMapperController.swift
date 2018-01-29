//
//  TableViewMapperController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 6/12/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableViewMapperController<C: CellMapperAdapter, E: DataLoaderEngine>: TableLoaderController<TableViewMapperAdapter<C, E>, E> {
  public var cellAdapter: C {
    return listAdapter.cellAdapter
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(cellAdapter: C, dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init(listAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoader: dataLoader))
  }
}
