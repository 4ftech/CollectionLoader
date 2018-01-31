//
//  ListNibMapperController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

import ViewMapper
import DataSource

open class ListNibMapperController<L: UIScrollView, V: ViewMappable, E>: ListCellMapperController<L, NibCellMapperAdapter<V>, E> where E: DataLoaderEngine<V.T> {
  
  // MARK: CellMapper
  public init(cellMapper: CellMapper<V> = CellMapper<V>(),
              dataLoader: DataLoader<T, E> = DataLoader(dataLoaderEngine: E()),
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(cellMapper: cellMapper),
               dataLoader: dataLoader,
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  public init(cellMapper: CellMapper<V> = CellMapper<V>(),
              dataLoaderEngine: E,
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(cellMapper: cellMapper),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  // MARK: UINib
  public init(nib: UINib,
              dataLoader: DataLoader<T, E> = DataLoader(dataLoaderEngine: E()),
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib),
               dataLoader: dataLoader,
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  public init(nib: UINib,
              dataLoaderEngine: E,
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  // MARK: nibName
  public init(nibName: String,
              dataLoader: DataLoader<T, E> = DataLoader(dataLoaderEngine: E()),
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName),
               dataLoader: dataLoader,
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  public init(nibName: String,
              dataLoaderEngine: E,
              viewHandler: ListViewHandler<L> = ListViewHandler<L>(),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               viewHandler: viewHandler,
               initialize: initialize)
  }
  
  // MARK: listAdapter
  public override init(listAdapter: ListCellMapperAdapter<NibCellMapperAdapter<V>, E>,
                       viewHandler: ListViewHandler<L> = ListViewHandler<L>()) {
    
    super.init(listAdapter: listAdapter, viewHandler: viewHandler)
  }
  
  public init(listAdapter: ListNibMapperAdapter<V, E>,
              viewHandler: ListViewHandler<L> = ListViewHandler<L>()) {
    
    super.init(listAdapter: listAdapter, viewHandler: viewHandler)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
