//
//  ListCellMapperController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

import ViewMapper
import ObjectMapperDataSource

open class ListCellMapperController<L: UIScrollView, C: CellMapperAdapter, E>: ListLoaderAdapterController<L, C.T.T, E, ListCellMapperAdapter<C, E>> where E:DataLoaderEngine<C.T.T> {
  public typealias T = C.T.T
  public var cellAdapter: C!
  
  let AdapterType = ListCellMapperAdapter<C, E>.self
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public static func listAdapter(cellAdapter: C,
                               dataLoader: DataLoader<T, E>,
                               initialize: ((C) -> Void)? = nil) -> ListCellMapperAdapter<C, E> {
    
    return ListCellMapperAdapter(cellAdapter: cellAdapter, dataLoader: dataLoader, initialize: initialize)
  }
  
  public init(cellAdapter: C,
              dataLoader: DataLoader<T, E> = DataLoader(dataLoaderEngine: E()),
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((C) -> Void)? = nil) {
    
    let listAdapter = type(of: self).listAdapter(cellAdapter: cellAdapter,
                                                 dataLoader: dataLoader,
                                                 initialize: initialize)
    
    super.init(listAdapter: listAdapter, viewHandler: viewHandler)
    
    self.initialize(cellAdapter: cellAdapter)
  }
  
  //  public init(cellAdapter: C,
  //              dataLoaderEngine: E,
  //              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
  //              initialize: ((C) -> Void)? = nil) {
  //    
  //    let listAdapter = type(of: self).listAdapter(cellAdapter: cellAdapter,
  //                                                 dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
  //                                                 initialize: initialize)
  //    
  //    super.init(listAdapter: listAdapter, viewHandler: viewHandler)
  //
  //    self.initialize(cellAdapter: cellAdapter)
  //  }
  
  public override init(listAdapter: ListCellMapperAdapter<C, E>,
                       viewHandler: ListViewHandler<L> = ListViewHandler<L>()) {
    
    super.init(listAdapter: listAdapter,
               viewHandler: viewHandler)
    
    self.initialize(cellAdapter: listAdapter.cellAdapter)
  }
  
  open func initialize(cellAdapter: C) {
    self.cellAdapter = cellAdapter
    self.listAdapter.viewController = self
  }
}
