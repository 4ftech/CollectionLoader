//
//  ListCellMapperController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

import ViewMapper
import DataSource

open class ListCellMapperController<C: CellMapperAdapter>: ListLoaderController<C.T.T> where C.T.T:BaseDataModel {
  public typealias T = C.T.T
  public var cellAdapter: C!
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  open static func listAdapter(listType: ListType, cellAdapter: C, dataLoader: DataLoader<T>, initialize: ((C) -> Void)? = nil) -> ListCellMapperAdapter<C> {
    return ListCellMapperAdapter(cellAdapter: cellAdapter, dataLoader: dataLoader, initialize: initialize)
  }
  
  public init(listType: ListType, cellAdapter: C, dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: DataLoaderEngine<T>()), initialize: ((C) -> Void)? = nil) {
    super.init(listType: listType, listAdapter: ListCellMapperController.listAdapter(listType: listType, cellAdapter: cellAdapter, dataLoader: dataLoader, initialize: initialize))
    
    self.initialize(cellAdapter: cellAdapter)
  }
  
  public init(listType: ListType, cellAdapter: C, dataLoaderEngine: DataLoaderEngine<T>, initialize: ((C) -> Void)? = nil) {
    super.init(listType: listType, listAdapter: ListCellMapperController.listAdapter(listType: listType, cellAdapter: cellAdapter, dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine), initialize: initialize))

    self.initialize(cellAdapter: cellAdapter)
  }
  
  public init(listType: ListType, listAdapter: ListCellMapperAdapter<C>) {
    super.init(listType: listType, listAdapter: listAdapter)
  }
  
  open func initialize(cellAdapter: C) {
    self.cellAdapter = cellAdapter
    
    let listAdapter = self.listAdapter as! ListCellMapperAdapter<C>
    listAdapter.viewController = self
  }
}
